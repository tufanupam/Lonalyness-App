/// AI Muse — Memory Repository
/// Handles long-term memory storage and retrieval from Firestore.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/memory_entity.dart';
import '../../domain/entities/relationship_entity.dart';

/// Repository for memory and relationship operations.
class MemoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Memory Operations ──────────────────────────────────────────

  /// Get all memories for a user-persona pair, sorted by importance.
  Future<List<MemoryEntity>> getMemories(
      String userId, String personaId) async {
    final snapshot = await _firestore
        .collection('memories')
        .where('userId', isEqualTo: userId)
        .where('personaId', isEqualTo: personaId)
        .orderBy('importance', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => MemoryEntity.fromMap(doc.data()))
        .toList();
  }

  /// Add a new memory.
  Future<void> addMemory({
    required String userId,
    required String personaId,
    required String category,
    required String content,
    double importance = 0.5,
  }) async {
    final memory = MemoryEntity(
      id: _uuid.v4(),
      userId: userId,
      personaId: personaId,
      category: category,
      content: content,
      importance: importance,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );

    await _firestore.collection('memories').doc(memory.id).set(memory.toMap());
  }

  /// Delete a memory by ID.
  Future<void> deleteMemory(String memoryId) async {
    await _firestore.collection('memories').doc(memoryId).delete();
  }

  // ── Relationship Operations ────────────────────────────────────

  /// Get or create relationship for a user-persona pair.
  Future<RelationshipEntity> getRelationship(
      String userId, String personaId) async {
    final docId = '${userId}_$personaId';
    final doc = await _firestore.collection('relationships').doc(docId).get();

    if (doc.exists) {
      return RelationshipEntity.fromMap(doc.data()!);
    }

    // Create new relationship
    final relationship = RelationshipEntity(
      userId: userId,
      personaId: personaId,
      firstInteraction: DateTime.now(),
      lastInteraction: DateTime.now(),
    );

    await _firestore
        .collection('relationships')
        .doc(docId)
        .set(relationship.toMap());

    return relationship;
  }

  /// Add XP and update relationship stats.
  Future<RelationshipEntity> addXp({
    required String userId,
    required String personaId,
    required int xpAmount,
    String? badge,
  }) async {
    final current = await getRelationship(userId, personaId);
    final newXp = current.xp + xpAmount;
    int newLevel = current.level;

    // Check for level up
    while (newXp >= newLevel * 50 + 100) {
      newLevel++;
    }

    final badges = [...current.badges];
    if (badge != null && !badges.contains(badge)) {
      badges.add(badge);
    }

    final updated = current.copyWith(
      xp: newXp,
      level: newLevel,
      badges: badges,
      totalMessages: current.totalMessages + 1,
      lastInteraction: DateTime.now(),
    );

    final docId = '${userId}_$personaId';
    await _firestore
        .collection('relationships')
        .doc(docId)
        .update(updated.toMap());

    return updated;
  }

  /// Get all relationships for a user.
  Future<List<RelationshipEntity>> getUserRelationships(String userId) async {
    final snapshot = await _firestore
        .collection('relationships')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => RelationshipEntity.fromMap(doc.data()))
        .toList();
  }
}
