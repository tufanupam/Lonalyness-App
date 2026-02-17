/// AI Muse — Memory Entity
/// Domain model for long-term AI memory storage.
library;

import 'package:equatable/equatable.dart';

/// Represents a stored memory/fact about the user.
class MemoryEntity extends Equatable {
  final String id;
  final String userId;
  final String personaId;
  final String category; // e.g., "preference", "fact", "emotion", "topic"
  final String content;
  final double importance; // 0.0 - 1.0
  final DateTime createdAt;
  final DateTime lastAccessed;

  const MemoryEntity({
    required this.id,
    required this.userId,
    required this.personaId,
    required this.category,
    required this.content,
    this.importance = 0.5,
    required this.createdAt,
    required this.lastAccessed,
  });

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'personaId': personaId,
      'category': category,
      'content': content,
      'importance': importance,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  /// Create from Firestore map.
  factory MemoryEntity.fromMap(Map<String, dynamic> map) {
    return MemoryEntity(
      id: map['id'] as String,
      userId: map['userId'] as String,
      personaId: map['personaId'] as String,
      category: map['category'] as String,
      content: map['content'] as String,
      importance: (map['importance'] as num?)?.toDouble() ?? 0.5,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastAccessed: DateTime.parse(map['lastAccessed'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, personaId, category, content];
}
