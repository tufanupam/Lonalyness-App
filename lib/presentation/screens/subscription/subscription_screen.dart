/// AI Muse — Subscription Screen
/// Premium subscription plans with feature comparison and purchase flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/repositories/subscription_repository.dart';

/// Subscription management screen with tier cards.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isYearly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Premium'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Header ─────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD740), Color(0xFFFF9100)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warning.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 36,
              ),
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 20),
            Text('Unlock AI Muse Premium',
                    style: context.textTheme.headlineMedium)
                .animate()
                .fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Get unlimited access to all personas, voice & video calls, and exclusive content.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 28),

            // ── Billing Toggle ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  _buildToggle('Monthly', !_isYearly, () {
                    setState(() => _isYearly = false);
                  }),
                  _buildToggle('Yearly (-33%)', _isYearly, () {
                    setState(() => _isYearly = true);
                  }),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // ── Plan Cards ─────────────────────────────────────
            ...SubscriptionRepository.plans.map((plan) {
              final isPremium = plan.id == 'premium';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanCard(context, plan, isPremium),
              )
                  .animate()
                  .fadeIn(delay: (500 + (isPremium ? 150 : 0)).ms)
                  .slideY(begin: 0.1);
            }),

            const SizedBox(height: 16),

            // ── Terms ──────────────────────────────────────────
            Text(
              'Cancel anytime. Payment will be charged through your app store account.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, SubscriptionPlan plan, bool isPremium) {
    final price = _isYearly ? plan.priceYearly : plan.priceMonthly;
    final period = _isYearly ? '/year' : '/month';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPremium ? null : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isPremium ? AppTheme.accent : AppTheme.divider,
          width: isPremium ? 2 : 1,
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header
          Row(
            children: [
              Text(plan.name, style: context.textTheme.headlineMedium),
              const Spacer(),
              if (isPremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD740), Color(0xFFFF9100)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
                style: context.textTheme.displayMedium?.copyWith(
                  color: isPremium ? AppTheme.accent : AppTheme.textPrimary,
                ),
              ),
              if (price > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    period,
                    style: context.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Features
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color:
                          isPremium ? AppTheme.accent : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      f,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: isPremium
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          // CTA
          SizedBox(
            width: double.infinity,
            child: isPremium
                ? ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Stripe/Razorpay payment
                      context.showSnackBar(
                          'Payment integration coming soon!');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Get Premium'),
                  )
                : OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Current Plan'),
                  ),
          ),
        ],
      ),
    );
  }
}
