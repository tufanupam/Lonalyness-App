/// AI Muse — Message Entity
/// Domain model for chat messages.
library;

import 'package:equatable/equatable.dart';

/// Role of the message sender.
enum MessageRole { user, assistant, system }

/// Type of message content.
enum MessageType { text, voice, image, system }

/// Represents a single chat message.
class MessageEntity extends Equatable {
  final String id;
  final String personaId;
  final String userId;
  final MessageRole role;
  final MessageType type;
  final String content;
  final String? audioUrl;
  final String? imageUrl;
  final String language;
  final DateTime timestamp;
  final bool isStreaming;

  const MessageEntity({
    required this.id,
    required this.personaId,
    required this.userId,
    required this.role,
    this.type = MessageType.text,
    required this.content,
    this.audioUrl,
    this.imageUrl,
    this.language = 'en',
    required this.timestamp,
    this.isStreaming = false,
  });

  /// Create a copy with modified fields.
  MessageEntity copyWith({
    String? id,
    String? personaId,
    String? userId,
    MessageRole? role,
    MessageType? type,
    String? content,
    String? audioUrl,
    String? imageUrl,
    String? language,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      personaId: personaId ?? this.personaId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      language: language ?? this.language,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personaId': personaId,
      'userId': userId,
      'role': role.name,
      'type': type.name,
      'content': content,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'language': language,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from Firestore map.
  factory MessageEntity.fromMap(Map<String, dynamic> map) {
    return MessageEntity(
      id: map['id'] as String,
      personaId: map['personaId'] as String,
      userId: map['userId'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      content: map['content'] as String,
      audioUrl: map['audioUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
      language: map['language'] as String? ?? 'en',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [id, personaId, role, content, timestamp];
}
