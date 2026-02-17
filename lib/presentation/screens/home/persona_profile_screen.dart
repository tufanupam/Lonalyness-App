/// AI Muse — Persona Profile Screen
/// Detailed persona view with avatar, bio, relationship progress, and actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/relationship_progress_bar.dart';

/// Profile screen for a specific AI persona.
class PersonaProfileScreen extends ConsumerWidget {
  final String personaId;
  const PersonaProfileScreen({super.key, required this.personaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaByIdProvider(personaId));

    if (persona == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    Color accentColor;
    try {
      accentColor =
          Color(int.parse(persona.accentColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      accentColor = AppTheme.accent;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: 0.15),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Top Bar ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // ── Avatar ─────────────────────────────────────
                const SizedBox(height: 20),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.4),
                        accentColor.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(color: accentColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      persona.name.substring(0, 1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .shimmer(delay: 600.ms, duration: 1500.ms),

                const SizedBox(height: 20),

                // ── Name & Tagline ─────────────────────────────
                Text(persona.name, style: context.textTheme.displayMedium)
                    .animate()
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    persona.tagline,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),

                // ── Relationship Progress ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: RelationshipProgressBar(
                    level: 3,
                    currentXp: 120,
                    maxXp: 250,
                    title: 'Friend',
                    accentColor: accentColor,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // ── Action Buttons ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat',
                        color: accentColor,
                        onTap: () => context.push('/chat/$personaId'),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        context,
                        icon: Icons.phone_rounded,
                        label: 'Voice',
                        color: AppTheme.success,
                        onTap: () =>
                            context.push('/voice-call/$personaId'),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        context,
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        color: AppTheme.accentCrux,
                        onTap: () =>
                            context.push('/video-call/$personaId'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // ── Bio Section ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About',
                            style: context.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text(
                          persona.bio,
                          style: context.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 16),

                // ── Personality Traits ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personality',
                            style: context.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _buildTraitRow(context, 'Tone', persona.tone),
                        const SizedBox(height: 8),
                        _buildTraitRow(context, 'Emotional Style',
                            persona.emotionalBehavior),
                        const SizedBox(height: 8),
                        _buildTraitRow(
                          context,
                          'Languages',
                          persona.supportedLanguages.join(', ').toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraitRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
