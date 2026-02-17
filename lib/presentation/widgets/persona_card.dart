/// AI Muse — Persona Card Widget
/// Reusable card showing persona avatar, name, tagline, and accent glow.
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/persona_entity.dart';

/// A premium card widget for displaying an AI persona.
class PersonaCard extends StatelessWidget {
  final PersonaEntity persona;
  final VoidCallback? onTap;

  const PersonaCard({
    super.key,
    required this.persona,
    this.onTap,
  });

  Color get _accentColor {
    try {
      return Color(
        int.parse(persona.accentColor.replaceFirst('#', '0xFF')),
      );
    } catch (_) {
      return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.cardColor,
              _accentColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _accentColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withValues(alpha: 0.3),
                    _accentColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  persona.name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    persona.tagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Persona traits chips
                  Wrap(
                    spacing: 6,
                    children: persona.tone
                        .split(',')
                        .take(3)
                        .map((trait) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                trait.trim(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: _accentColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
