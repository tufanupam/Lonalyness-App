import 'dart:ui';
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

  // Helper to parse hex color safely
  Color _getAccentColor(String? hex) {
    if (hex == null) return AppTheme.accentCrux;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.accentCrux;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaByIdProvider(personaId));

    if (persona == null) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentCrux)),
      );
    }

    final accentColor = _getAccentColor(persona.accentColor);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
             child: Image.network(
                persona.avatarPath.isNotEmpty ? persona.avatarPath : 'https://placehold.co/800x1200/png?text=${persona.name}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryBlack),
             ),
          ),

          // 2. Blur & Gradient Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      AppTheme.primaryBlack.withOpacity(0.8),
                      AppTheme.primaryBlack,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        "Persona Profile",
                        style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Avatar
                        Hero(
                          tag: 'avatar_${persona.id}',
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor, width: 3),
                              image: DecorationImage(
                                image: NetworkImage(persona.avatarPath),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 24),

                        // Name & Tagline
                        Text(
                          persona.name,
                          style: AppTheme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 8),

                        Text(
                          persona.tagline,
                          textAlign: TextAlign.center,
                          style: AppTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.silver,
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 32),

                        // Relationship Bar
                        RelationshipProgressBar(
                           level: 3, 
                           currentXp: 120, 
                           maxXp: 250, 
                           title: "Friend",
                           accentColor: accentColor,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ActionButton(icon: Icons.chat_bubble_rounded, label: "Chat", color: accentColor, onTap: () => context.push('/chat/$personaId')),
                            const SizedBox(width: 20),
                            _ActionButton(icon: Icons.call_rounded, label: "Call", color: AppTheme.success, onTap: () => context.push('/voice-call/$personaId')),
                            const SizedBox(width: 20),
                            _ActionButton(icon: Icons.videocam_rounded, label: "Video", color: AppTheme.accentRose, onTap: () => context.push('/video-call/$personaId')),
                          ],
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                        const SizedBox(height: 40),

                        // Settings / Info
                        _Section(
                          title: "Personality",
                          children: [
                             _InfoTile(label: "Tone", value: persona.tone, icon: Icons.record_voice_over_outlined),
                             _InfoTile(label: "Style", value: persona.emotionalBehavior, icon: Icons.psychology_outlined),
                             _InfoTile(label: "Languages", value: persona.supportedLanguages.join(", ").toUpperCase(), icon: Icons.translate_rounded),
                          ]
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 24),

                        _Section(
                          title: "Bio",
                          children: [
                             Text(
                               persona.bio,
                               style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.silver, height: 1.6),
                             ),
                          ]
                        ).animate().fadeIn(delay: 600.ms),
                        
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.silver, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey)),
          const Spacer(),
          Text(value, style: AppTheme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
