/// AI Muse — Chat Provider
/// Riverpod providers for chat state management.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/memory_repository.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/memory_entity.dart';
import 'auth_provider.dart';
import 'persona_provider.dart';

/// Provides the ChatRepository instance.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// Provides the MemoryRepository instance.
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});

/// Chat state for a specific persona conversation.
class ChatState {
  final List<MessageEntity> messages;
  final bool isLoading;
  final String? streamingContent;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.streamingContent,
    this.error,
  });

  ChatState copyWith({
    List<MessageEntity>? messages,
    bool? isLoading,
    String? streamingContent,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      streamingContent: streamingContent,
      error: error,
    );
  }
}

/// Chat notifier — manages messages, streaming, and AI interactions.
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, personaId) => ChatNotifier(ref, personaId),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final String personaId;
  final _uuid = const Uuid();
  StreamSubscription? _streamSub;

  ChatNotifier(this._ref, this.personaId) : super(const ChatState()) {
    _loadMessages();
  }

  /// Load existing messages from Firestore.
  void _loadMessages() {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final repo = _ref.read(chatRepositoryProvider);
    _streamSub = repo.getMessages(user.uid, personaId).listen(
      (messages) {
        if (mounted) {
          state = state.copyWith(messages: messages);
        }
      },
      onError: (e) {
        if (mounted) {
          state = state.copyWith(error: e.toString());
        }
      },
    );
  }

  /// Send a message and receive AI streaming response.
  Future<void> sendMessage(String content) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    final persona = _ref.read(personaByIdProvider(personaId));
    if (user == null || persona == null) return;

    // Create user message
    final userMessage = MessageEntity(
      id: _uuid.v4(),
      personaId: personaId,
      userId: user.uid,
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );

    // Add user message to state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      streamingContent: '',
    );

    try {
      // Get memories for context
      final memoryRepo = _ref.read(memoryRepositoryProvider);
      final memories = await memoryRepo.getMemories(user.uid, personaId);

      // Stream AI response
      final chatRepo = _ref.read(chatRepositoryProvider);
      final stream = chatRepo.sendMessage(
        userId: user.uid,
        userMessage: userMessage,
        persona: persona,
        chatHistory: state.messages,
        memories: memories,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        state = state.copyWith(streamingContent: chunk);
      }

      // Add final AI message to state
      if (mounted) {
        final aiMessage = MessageEntity(
          id: _uuid.v4(),
          personaId: personaId,
          userId: user.uid,
          role: MessageRole.assistant,
          content: state.streamingContent ?? '',
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
          streamingContent: null,
        );

        // Add XP for the interaction
        await memoryRepo.addXp(
          userId: user.uid,
          personaId: personaId,
          xpAmount: 10,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
