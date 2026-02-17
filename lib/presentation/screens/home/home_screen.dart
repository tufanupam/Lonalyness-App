import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/persona_entity.dart';
import '../../providers/persona_provider.dart';

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
          child: CircularProgressIndicator(color: AppTheme.white),
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
          top: 60,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Muse',
                style: AppTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
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
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImmersivePersonaCard extends StatelessWidget {
  final PersonaEntity persona;

  const _ImmersivePersonaCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. High-Res Image Background
        Image.asset(
          persona.avatarPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback gradient if image missing
             return Container(
               color: Color(0xFF1C1C1E),
               child: const Center(
                 child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
               ),
             );
          },
        ),

        // 2. Cinematic Gradient Overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black45, // Top darker for text visibility
                Colors.transparent,
                Colors.black54, // Bottom darker for controls
                Colors.black87,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),

        // 3. Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice Note Preview
              _GlassVoicePreview(persona: persona),
              
              const SizedBox(height: 24),

              // Name & Tagline
              Text(
                persona.name,
                style: AppTheme.textTheme.displayLarge,
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 8),
              
              Text(
                persona.tagline,
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 32),

              // Action Buttons (Minimalist Glass)
              Row(
                children: [
                  Expanded(
                    child: _GlassButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: "Chat",
                      onTap: () => context.pushNamed('chat', pathParameters: {'personaId': persona.id}),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GlassButton(
                      icon: Icons.call_outlined, // Changed to outline for cleaner look
                      label: "Call",
                      onTap: () => context.pushNamed('voiceCall', pathParameters: {'personaId': persona.id}),
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassVoicePreview extends StatelessWidget {
  final PersonaEntity persona;

  const _GlassVoicePreview({required this.persona});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white, // Minimal white
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Morning Note",
                    style: AppTheme.textTheme.labelLarge?.copyWith(
                      fontSize: 12, 
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 12,
                    width: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(12, (index) {
                         // Randomized visual for waveform
                         return Expanded(
                           child: Container(
                             margin: const EdgeInsets.symmetric(horizontal: 1.5),
                             height: 4 + (index % 4) * 3.0, 
                             decoration: BoxDecoration(
                               color: Colors.white,
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
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1);
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.white : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  color: isPrimary ? Colors.black : Colors.white, 
                  size: 24
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTheme.textTheme.labelLarge?.copyWith(
                    color: isPrimary ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
