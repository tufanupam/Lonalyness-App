import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Navigate after delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // 1. Moving Gradient Background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F0F1E), // Deep dark blue/purple
                      Color(0xFF000000),
                      Color(0xFF1A0033), // Deep purple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    transform: GradientRotation(_controller.value * 0.5),
                  ),
                ),
              );
            },
          ),

          // 2. Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo Orb
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentCrux.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          radius: 0.8,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(duration: 2.seconds, begin: const Offset(1,1), end: const Offset(1.5, 1.5)),
                    
                    // Inner Orb
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentCrux.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ).animate()
                 .scale(duration: 800.ms, curve: Curves.elasticOut)
                 .shimmer(delay: 800.ms, duration: 1200.ms),

                const SizedBox(height: 50),

                // Title with Letter Spacing
                Text(
                  'AI MUSE',
                  style: AppTheme.textTheme.displayLarge?.copyWith(
                    letterSpacing: 8.0,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: AppTheme.accentCrux.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.2),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Your AI Muse. Always with you.',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.silver,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 1.seconds),
              ],
            ),
          ),
          
          // 3. Loading Indicator (Subtle)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppTheme.accentCrux.withOpacity(0.5),
                  strokeWidth: 2,
                ),
              ),
            ).animate().fadeIn(delay: 1.seconds),
          ),
        ],
      ),
    );
  }
}
