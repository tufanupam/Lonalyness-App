/// AI Muse — Persona Provider
/// Riverpod providers for AI persona management.
library;

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/persona_entity.dart';

/// Loads all persona configurations from asset files.
final personasProvider = FutureProvider<List<PersonaEntity>>((ref) async {
  final personaFiles = [
    'config/personas/aria_realistic.json',
    'config/personas/sonam_eon.json',
    'config/personas/elena_virelli.json',
    'config/personas/yuna_seori.json',
  ];

  final personas = <PersonaEntity>[];

  for (final file in personaFiles) {
    try {
      final jsonStr = await rootBundle.loadString(file);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      personas.add(PersonaEntity.fromJson(json));
    } catch (e) {
      // Log error but don't crash — skip malformed configs
      // ignore: avoid_print
      print('Error loading persona config $file: $e');
    }
  }

  return personas;
});

/// Currently selected persona ID.
final selectedPersonaIdProvider = StateProvider<String?>((ref) => null);

/// Gets the currently selected persona entity.
final selectedPersonaProvider = Provider<PersonaEntity?>((ref) {
  final personaId = ref.watch(selectedPersonaIdProvider);
  final personasAsync = ref.watch(personasProvider);

  return personasAsync.whenOrNull(
    data: (personas) {
      if (personaId == null) return personas.isNotEmpty ? personas.first : null;
      return personas.firstWhere(
        (p) => p.id == personaId,
        orElse: () => personas.first,
      );
    },
  );
});

/// Gets a persona by ID.
final personaByIdProvider =
    Provider.family<PersonaEntity?, String>((ref, personaId) {
  final personasAsync = ref.watch(personasProvider);

  return personasAsync.whenOrNull(
    data: (personas) {
      try {
        return personas.firstWhere((p) => p.id == personaId);
      } catch (_) {
        return null;
      }
    },
  );
});
