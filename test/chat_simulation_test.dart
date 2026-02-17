
import 'package:ai_muse/data/repositories/chat_repository.dart';
import 'package:ai_muse/domain/entities/message_entity.dart';
import 'package:ai_muse/domain/entities/persona_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRepository (Offline Simulation)', () {
    late ChatRepository repository;

    setUp(() {
      repository = ChatRepository();
    });

    test('sendMessage should return a stream of characters from local engine', () async {
      final userMessage = MessageEntity(
        id: '1',
        personaId: 'aria',
        userId: 'test_user',
        role: MessageRole.user,
        content: 'Hello, are you real?',
        timestamp: DateTime.now(),
      );

      final persona = const PersonaEntity(
        id: 'aria',
        name: 'Aria',
        tagline: 'Test Persona',
        bio: 'I am a test persona.',
        avatarPath: 'assets/images/aria.png', 
        tone: 'Friendly',
        emotionalBehavior: 'Empathetic',
        defaultLanguage: 'en',
        supportedLanguages: ['en'],
        systemPrompt: '',
        voiceId: 'default',
        accentColor: '#FF0000',
        greetings: {},
      );

      final stream = repository.sendMessage(
        userId: 'test_user',
        userMessage: userMessage,
        persona: persona,
        chatHistory: [],
        memories: [],
      );

      final events = <String>[];
      await for (final chunk in stream) {
        events.add(chunk);
      }

      // Verify we got a response
      expect(events, isNotEmpty);
      final fullResponse = events.last;
      print('AI Response: $fullResponse');
      
      // Verify content logic (it should match one of the predefined responses)
      // "real" triggers: "I perceive you..."
      expect(fullResponse, contains("I perceive you"));
    });
  });
}
