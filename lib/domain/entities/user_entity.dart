/// AI Muse — User Entity
/// Domain model for authenticated users with subscription & relationship data.
library;

import 'package:equatable/equatable.dart';

/// Subscription tier for monetization.
enum SubscriptionTier { free, premium }

/// Core user entity used across the domain layer.
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final SubscriptionTier subscriptionTier;
  final int totalXp;
  final int level;
  final List<String> badges;
  final String preferredLanguage;
  final int messagesUsedToday;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.subscriptionTier = SubscriptionTier.free,
    this.totalXp = 0,
    this.level = 1,
    this.badges = const [],
    this.preferredLanguage = 'en',
    this.messagesUsedToday = 0,
    required this.createdAt,
  });

  /// Check if user has premium access.
  bool get isPremium => subscriptionTier == SubscriptionTier.premium;

  /// Calculate XP needed for next level (exponential curve).
  int get xpForNextLevel => level * 100;

  /// Progress to next level as fraction (0.0 - 1.0).
  double get levelProgress {
    final xpInCurrentLevel = totalXp - _cumulativeXpForLevel(level - 1);
    return (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
  }

  int _cumulativeXpForLevel(int lvl) {
    int total = 0;
    for (int i = 1; i <= lvl; i++) {
      total += i * 100;
    }
    return total;
  }

  /// Create a copy with modified fields.
  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    SubscriptionTier? subscriptionTier,
    int? totalXp,
    int? level,
    List<String>? badges,
    String? preferredLanguage,
    int? messagesUsedToday,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      messagesUsedToday: messagesUsedToday ?? this.messagesUsedToday,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'subscriptionTier': subscriptionTier.name,
      'totalXp': totalXp,
      'level': level,
      'badges': badges,
      'preferredLanguage': preferredLanguage,
      'messagesUsedToday': messagesUsedToday,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from Firestore map.
  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (e) => e.name == map['subscriptionTier'],
        orElse: () => SubscriptionTier.free,
      ),
      totalXp: map['totalXp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      badges: List<String>.from(map['badges'] ?? []),
      preferredLanguage: map['preferredLanguage'] as String? ?? 'en',
      messagesUsedToday: map['messagesUsedToday'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [uid, email, subscriptionTier, totalXp, level];
}
