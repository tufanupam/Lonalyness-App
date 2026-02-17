/// AI Muse — Relationship Entity
/// Domain model for user-persona relationship tracking.
library;

import 'package:equatable/equatable.dart';

/// Relationship level titles that unlock at certain levels.
enum RelationshipLevel {
  stranger(1, 'Stranger'),
  acquaintance(5, 'Acquaintance'),
  friend(10, 'Friend'),
  closeFriend(20, 'Close Friend'),
  bestFriend(35, 'Best Friend'),
  soulmate(50, 'Soulmate');

  final int minLevel;
  final String title;
  const RelationshipLevel(this.minLevel, this.title);
}

/// Tracks the relationship between a user and a persona.
class RelationshipEntity extends Equatable {
  final String userId;
  final String personaId;
  final int xp;
  final int level;
  final List<String> badges;
  final int totalMessages;
  final int totalVoiceCalls;
  final int totalVideoCalls;
  final DateTime firstInteraction;
  final DateTime lastInteraction;

  const RelationshipEntity({
    required this.userId,
    required this.personaId,
    this.xp = 0,
    this.level = 1,
    this.badges = const [],
    this.totalMessages = 0,
    this.totalVoiceCalls = 0,
    this.totalVideoCalls = 0,
    required this.firstInteraction,
    required this.lastInteraction,
  });

  /// Current relationship level based on level number.
  RelationshipLevel get relationshipLevel {
    return RelationshipLevel.values.lastWhere(
      (r) => level >= r.minLevel,
      orElse: () => RelationshipLevel.stranger,
    );
  }

  /// XP needed for next level.
  int get xpForNextLevel => level * 50 + 100;

  /// Progress to next level (0.0 - 1.0).
  double get levelProgress => (xp % xpForNextLevel) / xpForNextLevel;

  /// Create a copy with modified fields.
  RelationshipEntity copyWith({
    int? xp,
    int? level,
    List<String>? badges,
    int? totalMessages,
    int? totalVoiceCalls,
    int? totalVideoCalls,
    DateTime? lastInteraction,
  }) {
    return RelationshipEntity(
      userId: userId,
      personaId: personaId,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      totalMessages: totalMessages ?? this.totalMessages,
      totalVoiceCalls: totalVoiceCalls ?? this.totalVoiceCalls,
      totalVideoCalls: totalVideoCalls ?? this.totalVideoCalls,
      firstInteraction: firstInteraction,
      lastInteraction: lastInteraction ?? this.lastInteraction,
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'personaId': personaId,
      'xp': xp,
      'level': level,
      'badges': badges,
      'totalMessages': totalMessages,
      'totalVoiceCalls': totalVoiceCalls,
      'totalVideoCalls': totalVideoCalls,
      'firstInteraction': firstInteraction.toIso8601String(),
      'lastInteraction': lastInteraction.toIso8601String(),
    };
  }

  /// Create from Firestore map.
  factory RelationshipEntity.fromMap(Map<String, dynamic> map) {
    return RelationshipEntity(
      userId: map['userId'] as String,
      personaId: map['personaId'] as String,
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      badges: List<String>.from(map['badges'] ?? []),
      totalMessages: map['totalMessages'] as int? ?? 0,
      totalVoiceCalls: map['totalVoiceCalls'] as int? ?? 0,
      totalVideoCalls: map['totalVideoCalls'] as int? ?? 0,
      firstInteraction: DateTime.parse(map['firstInteraction'] as String),
      lastInteraction: DateTime.parse(map['lastInteraction'] as String),
    );
  }

  @override
  List<Object?> get props => [userId, personaId, xp, level];
}
