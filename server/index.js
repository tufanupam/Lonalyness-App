/**
 * AI Muse — Backend Server
 *
 * Express server providing:
 * - /api/chat — Proxies OpenAI chat completions with SSE streaming
 * - /api/translate — Translation proxy endpoint
 * - /api/auth/verify — Firebase token verification
 * - /api/subscription/webhook — Stripe webhook handler
 *
 * Security: Helmet, CORS, rate limiting, token verification.
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const admin = require('firebase-admin');
const OpenAI = require('openai');
const Stripe = require('stripe');

// ── Initialize Services ──────────────────────────────────────────

// Firebase Admin
admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: process.env.FIREBASE_PROJECT_ID,
});

// OpenAI
const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

// Stripe
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// Express
const app = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ────────────────────────────────────────────────────

// Security headers
app.use(helmet());

// CORS
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
    max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
    message: { error: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// JSON body parser (except for Stripe webhook which needs raw body)
app.use((req, res, next) => {
    if (req.originalUrl === '/api/subscription/webhook') {
        next();
    } else {
        express.json({ limit: '10kb' })(req, res, next);
    }
});

// ── Auth Middleware ───────────────────────────────────────────────

/**
 * Verify Firebase Auth token from Authorization header.
 */
async function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing or invalid token' });
    }

    try {
        const token = authHeader.split('Bearer ')[1];
        const decoded = await admin.auth().verifyIdToken(token);
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Invalid or expired token' });
    }
}

// ── Routes ───────────────────────────────────────────────────────

/**
 * POST /api/chat
 * Proxies chat completion to OpenAI with SSE streaming.
 */
app.post('/api/chat', verifyToken, async (req, res) => {
    try {
        const { messages, model = 'gpt-4', temperature = 0.85, max_tokens = 1024 } = req.body;

        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({ error: 'Messages array is required' });
        }

        // Check user subscription for rate limiting
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(req.user.uid)
            .get();

        if (userDoc.exists) {
            const userData = userDoc.data();
            if (userData.subscriptionTier !== 'premium' && userData.messagesUsedToday >= 50) {
                return res.status(429).json({
                    error: 'Daily message limit reached. Upgrade to Premium for unlimited messages.',
                });
            }

            // Increment message count
            await admin.firestore()
                .collection('users')
                .doc(req.user.uid)
                .update({
                    messagesUsedToday: admin.firestore.FieldValue.increment(1),
                });
        }

        // Set SSE headers
        res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
        });

        // Stream from OpenAI
        const stream = await openai.chat.completions.create({
            model,
            messages,
            temperature,
            max_tokens,
            stream: true,
            presence_penalty: 0.6,
            frequency_penalty: 0.3,
        });

        for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content;
            if (content) {
                res.write(`data: ${JSON.stringify(chunk)}\n\n`);
            }
        }

        res.write('data: [DONE]\n\n');
        res.end();
    } catch (error) {
        console.error('Chat error:', error.message);
        if (!res.headersSent) {
            res.status(500).json({ error: 'Internal server error' });
        }
    }
});

/**
 * POST /api/translate
 * Translation endpoint using OpenAI.
 */
app.post('/api/translate', verifyToken, async (req, res) => {
    try {
        const { text, source, target } = req.body;

        if (!text || !source || !target) {
            return res.status(400).json({ error: 'text, source, and target are required' });
        }

        const response = await openai.chat.completions.create({
            model: 'gpt-4',
            messages: [
                {
                    role: 'system',
                    content: `You are a translator. Translate the following text from ${source} to ${target}. Only output the translated text, nothing else.`,
                },
                { role: 'user', content: text },
            ],
            temperature: 0.3,
            max_tokens: 1024,
        });

        const translatedText = response.choices[0]?.message?.content?.trim();
        res.json({ translatedText });
    } catch (error) {
        console.error('Translation error:', error.message);
        res.status(500).json({ error: 'Translation failed' });
    }
});

/**
 * POST /api/auth/verify
 * Verify Firebase Auth token and return user info.
 */
app.post('/api/auth/verify', verifyToken, (req, res) => {
    res.json({
        uid: req.user.uid,
        email: req.user.email,
        verified: true,
    });
});

/**
 * POST /api/subscription/webhook
 * Stripe webhook handler for subscription events.
 */
app.post('/api/subscription/webhook',
    express.raw({ type: 'application/json' }),
    async (req, res) => {
        const sig = req.headers['stripe-signature'];

        try {
            const event = stripe.webhooks.constructEvent(
                req.body,
                sig,
                process.env.STRIPE_WEBHOOK_SECRET,
            );

            switch (event.type) {
                case 'checkout.session.completed': {
                    const session = event.data.object;
                    const userId = session.metadata?.userId;
                    if (userId) {
                        await admin.firestore()
                            .collection('users')
                            .doc(userId)
                            .update({ subscriptionTier: 'premium' });
                        console.log(`✅ Premium activated for user: ${userId}`);
                    }
                    break;
                }

                case 'customer.subscription.deleted': {
                    const subscription = event.data.object;
                    const userId = subscription.metadata?.userId;
                    if (userId) {
                        await admin.firestore()
                            .collection('users')
                            .doc(userId)
                            .update({ subscriptionTier: 'free' });
                        console.log(`⚠️ Subscription cancelled for user: ${userId}`);
                    }
                    break;
                }
            }

            res.json({ received: true });
        } catch (error) {
            console.error('Webhook error:', error.message);
            res.status(400).json({ error: 'Webhook verification failed' });
        }
    }
);

/**
 * Health check endpoint.
 */
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ── Start Server ─────────────────────────────────────────────────
app.listen(PORT, () => {
    console.log(`🚀 AI Muse server running on port ${PORT}`);
    console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
