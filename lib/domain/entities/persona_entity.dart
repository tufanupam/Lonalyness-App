/// AI Muse — Persona Entity
/// Domain model for AI Influencer Personas.
library;

import 'package:equatable/equatable.dart';

/// Represents an AI persona with personality configuration.
class PersonaEntity extends Equatable {
  final String id;
  final String name;
  final String tagline;
  final String bio;
  final String avatarPath;
  final String tone;
  final String emotionalBehavior;
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final String systemPrompt;
  final String voiceId;
  final Map<String, String> greetings; // language -> greeting
  final String accentColor;

  const PersonaEntity({
    required this.id,
    required this.name,
    required this.tagline,
    required this.bio,
    required this.avatarPath,
    required this.tone,
    required this.emotionalBehavior,
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.systemPrompt,
    required this.voiceId,
    required this.greetings,
    required this.accentColor,
  });

  /// Create from JSON config map.
  factory PersonaEntity.fromJson(Map<String, dynamic> json) {
    return PersonaEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarPath: json['avatar'] as String,
      tone: json['tone'] as String,
      emotionalBehavior: json['emotionalBehavior'] as String,
      defaultLanguage: json['defaultLanguage'] as String? ?? 'en',
      supportedLanguages:
          List<String>.from(json['supportedLanguages'] ?? ['en']),
      systemPrompt: json['systemPrompt'] as String,
      voiceId: json['voiceId'] as String? ?? 'default',
      greetings: Map<String, String>.from(json['greetings'] ?? {}),
      accentColor: json['accentColor'] as String? ?? '#7C4DFF',
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'bio': bio,
      'avatar': avatarPath,
      'tone': tone,
      'emotionalBehavior': emotionalBehavior,
      'defaultLanguage': defaultLanguage,
      'supportedLanguages': supportedLanguages,
      'systemPrompt': systemPrompt,
      'voiceId': voiceId,
      'greetings': greetings,
      'accentColor': accentColor,
    };
  }

  @override
  List<Object?> get props => [id, name];
}
