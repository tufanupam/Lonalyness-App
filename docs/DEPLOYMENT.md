# AI Muse — Deployment Guide

## Prerequisites

- Flutter 3.x+ installed
- Node.js 18+ installed
- Firebase project created
- OpenAI API key
- Stripe account (for payments)

---

## 1. Firebase Setup

### Create Firebase Project
```bash
firebase login
firebase projects:create ai-muse-app
firebase use ai-muse-app
```

### Enable Services
1. **Authentication**: Enable Email/Password and Google Sign-In
2. **Cloud Firestore**: Create database in production mode
3. **Firebase Storage**: Enable for avatar uploads

### Configure Flutter
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter project
flutterfire configure --project=ai-muse-app
```

This generates `firebase_options.dart` in your `lib/` directory.

### Firestore Rules
Deploy security rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Messages are scoped to user
    match /conversations/{userId}/personas/{personaId}/messages/{messageId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Memories are scoped to user
    match /memories/{userId}/personas/{personaId}/entries/{memoryId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Relationships are scoped to user
    match /relationships/{userId}/personas/{personaId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## 2. Backend Server

### Install Dependencies
```bash
cd server
npm install
```

### Configure Environment
```bash
cp .env.example .env
# Edit .env with your credentials
```

### Run Locally
```bash
npm run dev
```

### Deploy to Render / Railway / Fly.io

**Render:**
1. Create Web Service → connect GitHub repo
2. Build command: `cd server && npm install`
3. Start command: `cd server && npm start`
4. Add environment variables from `.env`

**Railway:**
```bash
railway login
railway init
railway up
```

---

## 3. Flutter App

### Install Dependencies
```bash
flutter pub get
```

### Update API Endpoints
Edit `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'https://your-server-url.com';
```

### Build for Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### Build for iOS
```bash
flutter build ios --release
```

---

## 4. Stripe Setup

### Create Products
1. Go to Stripe Dashboard → Products
2. Create "AI Muse Premium" product
3. Add monthly ($9.99/mo) and yearly ($79.99/yr) prices
4. Copy Price IDs to your server config

### Configure Webhook
1. Stripe Dashboard → Webhooks → Add endpoint
2. URL: `https://your-server.com/api/subscription/webhook`
3. Events: `checkout.session.completed`, `customer.subscription.deleted`
4. Copy webhook secret to `STRIPE_WEBHOOK_SECRET`

---

## 5. Post-Deployment Checklist

- [ ] Firebase Auth providers enabled
- [ ] Firestore security rules deployed
- [ ] Backend server running and healthy (`/health` endpoint)
- [ ] OpenAI API key configured and tested
- [ ] Stripe webhook configured and verified
- [ ] CORS origins updated for production
- [ ] Rate limiting configured
- [ ] SSL/TLS enabled on all endpoints
- [ ] App Store / Play Store listing prepared
