import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/persona_entity.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/relationship_progress_bar.dart';

/// Home screen displaying AI personas in a full-screen immersive vertical scroll.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personasAsync = ref.watch(personasProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: personasAsync.when(
        data: (personas) => _HomeContent(personas: personas),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentCrux),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: AppTheme.textTheme.bodyMedium),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final List<PersonaEntity> personas;

  const _HomeContent({required this.personas});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full Screen Vertical Scroll
        PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _pageController,
          itemCount: widget.personas.length,
          itemBuilder: (context, index) {
            return _ImmersivePersonaCard(persona: widget.personas[index]);
          },
        ),

        // Custom Top Bar (Transparent)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.accentCrux, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'AI MUSE',
                        style: AppTheme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontSize: 20,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.profile),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                         decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceLight, 
                         ),
                         child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImmersivePersonaCard extends StatelessWidget {
  final PersonaEntity persona;

  const _ImmersivePersonaCard({required this.persona});

  // Helper to parse hex color safely
  Color _getAccentColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.accentCrux;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(persona.accentColor);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. High-Res Image Background
        Image.network(
          persona.avatarPath.isNotEmpty ? persona.avatarPath : 'https://placehold.co/800x1200/png?text=${persona.name}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
             return Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     Color(0xFF1C1C1E),
                     Color(0xFF000000),
                   ],
                 ),
               ),
               child: Center(
                 child: Icon(Icons.person_outline, size: 80, color: Colors.white.withOpacity(0.1)),
               ),
             );
          },
        ),

        // 2. Cinematic Gradient Overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black45, // Top darker
                Colors.transparent,
                Colors.transparent,
                Colors.black, // Bottom solid black
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
        
        // 2.5 Bottom Gradient for readability
        Align(
          alignment: Alignment.bottomCenter,
           child: Container(
             height: 400,
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 colors: [
                   Colors.transparent,
                   Colors.black.withOpacity(0.8),
                   Colors.black,
                 ],
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
               ),
             ),
           ),
        ),

        // 3. Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Relationship Bar (Floating)
              GestureDetector(
                onTap: () => context.pushNamed('personaProfile', pathParameters: {'personaId': persona.id}),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: accentColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Lv. 3 • Friend", // TODO: Real data
                        style: AppTheme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 60,
                        height: 4,
                        child: LinearProgressIndicator(
                          value: 0.6, // TODO: Real data
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              ),

              // Voice Note Preview
              _GlassVoicePreview(persona: persona, accentColor: accentColor),
              
              const SizedBox(height: 20),

              // Name with verified badge
              Row(
                children: [
                   Text(
                    persona.name,
                    style: AppTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  const SizedBox(width: 8),
                  Icon(Icons.verified, color: AppTheme.accentCrux, size: 24)
                    .animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                persona.tagline,
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.silver,
                  height: 1.4,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

              const SizedBox(height: 32),

              // Action Buttons (Full Width)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _GlassButton(
                      icon: Icons.chat_bubble_rounded,
                      label: "Chat",
                      onTap: () => context.pushNamed('chat', pathParameters: {'personaId': persona.id}),
                      isPrimary: true,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _GlassButton(
                      icon: Icons.phone_rounded,
                      label: "Call",
                      onTap: () => context.pushNamed('voiceCall', pathParameters: {'personaId': persona.id}),
                      isPrimary: false,
                      color: accentColor,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 20), 
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassVoicePreview extends StatelessWidget {
  final PersonaEntity persona;
  final Color accentColor;

  const _GlassVoicePreview({
    required this.persona, 
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 10,
                    )
                  ]
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Morning Motivation",
                    style: AppTheme.textTheme.labelLarge?.copyWith(
                      fontSize: 12, 
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 12,
                    width: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(16, (index) {
                         // Randomized visual for waveform
                         return Expanded(
                           child: Container(
                             margin: const EdgeInsets.symmetric(horizontal: 1.0),
                             height: 4 + ((index * 7) % 10.0), 
                             decoration: BoxDecoration(
                               color: AppTheme.silver,
                               borderRadius: BorderRadius.circular(1),
                             ),
                           ),
                         );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1);
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color color;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isPrimary ? color : Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: Colors.white, 
              size: 22 // Slightly smaller icon
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTheme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
