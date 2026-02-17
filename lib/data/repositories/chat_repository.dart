/// AI Muse — Chat Repository
/// Handles chat message persistence and AI response streaming.
library;

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/persona_entity.dart';
import '../../domain/entities/memory_entity.dart';

/// Repository for chat operations and AI interactions.
class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Get chat messages stream for a user-persona pair.
  Stream<List<MessageEntity>> getMessages(String userId, String personaId) {
    return _firestore
        .collection('chats')
        .doc('${userId}_$personaId')
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageEntity.fromMap(doc.data()))
          .toList();
    });
  }

  /// Send a message and get AI streaming response.
  Stream<String> sendMessage({
    required String userId,
    required MessageEntity userMessage,
    required PersonaEntity persona,
    required List<MessageEntity> chatHistory,
    required List<MemoryEntity> memories,
  }) async* {
    // Save user message to Firestore
    await _saveMessage(userMessage);

    // Build messages array for AI API
    final messages = _buildApiMessages(persona, chatHistory, memories);

    // Stream AI response via SSE
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatEndpoint}'),
      );

      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer \$API_KEY';

      request.body = jsonEncode({
        'model': 'gpt-4',
        'messages': messages,
        'stream': true,
        'temperature': 0.85,
        'max_tokens': 1024,
        'presence_penalty': 0.6,
        'frequency_penalty': 0.3,
      });

      final response = await client.send(request);
      final stream = response.stream.transform(utf8.decoder);

      final buffer = StringBuffer();

      await for (final chunk in stream) {
        // Parse SSE data chunks
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') break;

            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta']?['content'];
              if (delta != null) {
                buffer.write(delta);
                yield buffer.toString();
              }
            } catch (_) {
              // Skip malformed JSON chunks
            }
          }
        }
      }

      // Save AI response to Firestore
      final aiMessage = MessageEntity(
        id: _uuid.v4(),
        personaId: userMessage.personaId,
        userId: userId,
        role: MessageRole.assistant,
        content: buffer.toString(),
        timestamp: DateTime.now(),
      );
      await _saveMessage(aiMessage);
    } finally {
      client.close();
    }
  }

  /// Build messages array for the OpenAI API.
  List<Map<String, String>> _buildApiMessages(
    PersonaEntity persona,
    List<MessageEntity> chatHistory,
    List<MemoryEntity> memories,
  ) {
    final messages = <Map<String, String>>[];

    // System prompt with persona personality
    String systemPrompt = persona.systemPrompt;

    // Inject memories into system prompt
    if (memories.isNotEmpty) {
      final memoryContext = memories
          .map((m) => '- ${m.category}: ${m.content}')
          .join('\n');
      systemPrompt +=
          '\n\nHere are things you remember about this user:\n$memoryContext';
    }

    messages.add({'role': 'system', 'content': systemPrompt});

    // Add recent chat history (last 20 messages for context window)
    final recentHistory = chatHistory.length > 20
        ? chatHistory.sublist(chatHistory.length - 20)
        : chatHistory;

    for (final msg in recentHistory) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    return messages;
  }

  /// Save a message to Firestore.
  Future<void> _saveMessage(MessageEntity message) async {
    await _firestore
        .collection('chats')
        .doc('${message.userId}_${message.personaId}')
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  /// Delete all messages for a conversation.
  Future<void> clearChat(String userId, String personaId) async {
    final batch = _firestore.batch();
    final docs = await _firestore
        .collection('chats')
        .doc('${userId}_$personaId')
        .collection('messages')
        .get();

    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
