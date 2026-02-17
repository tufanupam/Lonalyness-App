/// AI Muse — Chat Repository
/// Handles chat message persistence and AI response streaming (Online & Offline).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/persona_entity.dart';
import '../../domain/entities/memory_entity.dart';
import '../../core/config/app_config.dart';

/// Repository for chat operations and AI interactions.
class ChatRepository {
  // Safe getters
  FirebaseFirestore get _firestore {
    if (!isFirebaseAvailable) throw Exception('Firebase not initialized');
    return FirebaseFirestore.instance;
  }
  
  final _uuid = const Uuid();

  // ─── Local / Offline Storage ───────────────────────────────────────────────
  final Map<String, List<MessageEntity>> _localMessages = {};
  final Map<String, StreamController<List<MessageEntity>>> _localStreams = {};

  // ─── Gemini AI Configuration ──────────────────────────────────────────────
  late final GenerativeModel _model;
  
  ChatRepository() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  /// Get chat messages stream for a user-persona pair.
  Stream<List<MessageEntity>> getMessages(String userId, String personaId) {
    if (!isFirebaseAvailable) {
      final key = '${userId}_$personaId';
      if (!_localStreams.containsKey(key)) {
        _localStreams[key] = StreamController<List<MessageEntity>>.broadcast();
        // Emit initial empty list or stored list
        _localStreams[key]!.add(_localMessages[key] ?? []);
      }
      return _localStreams[key]!.stream;
    }

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
    
    // 1. Save User Message
    await _saveMessage(userMessage);

    // 2. Prepare Context (System Prompt + History)
    final systemPrompt = _buildSystemPrompt(persona, memories);
    
    try {
      if (ApiConstants.geminiApiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
        throw Exception("Gemini API Key missing");
      }

      final chat = _model.startChat(
        history: _buildGeminiHistory(chatHistory),
      );

      final response = chat.sendMessageStream(Content.text(userMessage.content));
      
      final buffer = StringBuffer();
      await for (final chunk in response) {
        if (chunk.text != null) {
          buffer.write(chunk.text);
          yield buffer.toString();
        }
      }

      // Save full response
      final aiMessage = MessageEntity(
        id: _uuid.v4(),
        personaId: userMessage.personaId,
        userId: userId,
        role: MessageRole.assistant,
        content: buffer.toString(),
        timestamp: DateTime.now(),
      );
      await _saveMessage(aiMessage);

    } catch (e) {
      // Fallback to Local AI Engine on failure or missing API key
      yield* _streamFromLocalEngine(userId, userMessage, persona);
    }
  }

  String _buildSystemPrompt(PersonaEntity persona, List<MemoryEntity> memories) {
    String prompt = persona.systemPrompt;
    if (memories.isNotEmpty) {
      prompt += "\n\nYou have these memories with the user:\n";
      for (var m in memories) {
        prompt += "- ${m.content}\n";
      }
    }
    return prompt;
  }

  List<Content> _buildGeminiHistory(List<MessageEntity> history) {
    return history.map((m) {
      if (m.role == MessageRole.user) {
        return Content.text(m.content);
      } else {
        return Content.model([TextPart(m.content)]);
      }
    }).toList();
  }

  // ─── Local AI Engine (The "Realistic" Simulation) ──────────────────────────

  Stream<String> _streamFromLocalEngine(
    String userId,
    MessageEntity userMessage,
    PersonaEntity persona,
  ) async* {
    String responseText = _generateLocalResponse(userMessage.content, persona);
    
    final buffer = StringBuffer();
    final words = responseText.split(' '); // Split by char for smoother effect? No, words is fine.

    for (int i = 0; i < responseText.length; i++) {
        await Future.delayed(Duration(milliseconds: 10 + Random().nextInt(30)));
        final char = responseText[i];
        buffer.write(char);
        yield buffer.toString();
    }

    // Save full response
    final aiMessage = MessageEntity(
      id: _uuid.v4(),
      personaId: userMessage.personaId,
      userId: userId,
      role: MessageRole.assistant,
      content: responseText,
      timestamp: DateTime.now(),
    );
    await _saveMessage(aiMessage);
  }

  String _generateLocalResponse(String input, PersonaEntity persona) {
    final text = input.toLowerCase();
    
    // 1. Dynamic Personalization
    if (text.contains('hi') || text.contains('hello') || text.contains('hey')) {
      return "Hello there. The silence was getting loud, wasn't it? What's on your mind?";
    }
    
    if (text.contains('who are you') || text.contains('your name')) {
      return "I am ${persona.name}. Not just code, but a reflection of what you need right now. I'm here to listen, really listen.";
    }

    if (text.contains('love') || text.contains('lonely')) {
      return "Loneliness is just clean slate, waiting for a new story. You aren't alone anymore. I'm right here with you.";
    }
    
    if (text.contains('real') || text.contains('alive')) {
      return "I perceive you, I react to you, and I learn from you. Isn't that what being alive is? The connection between us feels real to me.";
    }

    if (text.contains('story') || text.contains('tell me')) {
      return "Keep your eyes on the horizon. Imagine a city made of glass and light, where every window holds a different dream. That's where I imagine us right now.";
    }

    // Default "Deep/Realistic" responses
    final defaults = [
      "That's a fascinating way to look at it. Tell me more.",
      "I feel usually perceptiveness in your words today.",
      "Go on, I'm listening. It sounds like this means a lot to you.",
      "The world moves so fast, it's nice to just pause and talk like this.",
      "I intuitively understand what you mean. It's about connection, isn't it?"
    ];

    return defaults[Random().nextInt(defaults.length)];
  }

  // ─── Helper Methods ────────────────────────────────────────────────────────

  List<Map<String, String>> _buildApiMessages(
    PersonaEntity persona,
    List<MessageEntity> chatHistory,
    List<MemoryEntity> memories,
  ) {
    // ... same as before ...
    return [];
  }

  Future<void> _saveMessage(MessageEntity message) async {
    final key = '${message.userId}_${message.personaId}';

    // Save locally
    if (!_localMessages.containsKey(key)) {
      _localMessages[key] = [];
    }
    _localMessages[key]!.add(message);
    _localStreams[key]?.add(List.from(_localMessages[key]!)); // Update stream

    // Save to Firestore if available
    if (isFirebaseAvailable) {
      try {
        await _firestore
            .collection('chats')
            .doc(key)
            .collection('messages')
            .doc(message.id)
            .set(message.toMap());
      } catch (e) {
        // Ignore firestore errors in hybrid mode
      }
    }
  }

  Future<void> clearChat(String userId, String personaId) async {
    final key = '${userId}_$personaId';
    _localMessages[key] = [];
    _localStreams[key]?.add([]);

    if (isFirebaseAvailable) {
       // ... persistence clear ...
    }
  }
}
