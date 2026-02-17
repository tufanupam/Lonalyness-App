/// AI Muse — Subscription Repository
/// Handles subscription state and payment integration.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Subscription plan details.
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double priceMonthly;
  final double priceYearly;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
  });
}

/// Repository for subscription and payment operations.
class SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Available subscription plans.
  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      description: 'Get started with AI Muse',
      priceMonthly: 0,
      priceYearly: 0,
      features: [
        '50 messages per day',
        'Text chat only',
        '1 persona unlock',
        'Basic memory',
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      description: 'Unlock the full AI Muse experience',
      priceMonthly: 9.99,
      priceYearly: 79.99,
      features: [
        'Unlimited messages',
        'Voice & video calls',
        'All personas unlocked',
        'Advanced memory',
        'Exclusive voice notes',
        'AI-generated photos',
        'Priority response speed',
        'Custom themes',
      ],
    ),
  ];

  /// Check current subscription status.
  Future<SubscriptionTier> getSubscriptionTier(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return SubscriptionTier.free;

    final tier = doc.data()?['subscriptionTier'] as String?;
    return tier == 'premium' ? SubscriptionTier.premium : SubscriptionTier.free;
  }

  /// Update subscription after successful payment.
  Future<void> activatePremium(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'subscriptionTier': 'premium',
      'subscriptionStartDate': DateTime.now().toIso8601String(),
    });
  }

  /// Cancel subscription.
  Future<void> cancelSubscription(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'subscriptionTier': 'free',
    });
  }

  /// Check if user has exceeded daily message limit.
  Future<bool> hasReachedMessageLimit(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;

    final user = UserEntity.fromMap(doc.data()!);
    if (user.isPremium) return false;

    return user.messagesUsedToday >= 50;
  }

  /// Increment daily message count.
  Future<void> incrementMessageCount(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'messagesUsedToday': FieldValue.increment(1),
    });
  }
}
