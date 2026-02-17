import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading delay then navigate to Onboarding
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Background Gradient Animation
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A0033), // Deep Purple/Black
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Center Application Logo & Tagline
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo Placeholder (Replace with actual asset)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [AppTheme.deepPurple, AppTheme.accentPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.white,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                .then()
                .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.5)),

                const SizedBox(height: 40),

                // Title
                Text(
                  'AI MUSE',
                  style: AppTheme.textTheme.displayLarge?.copyWith(
                    letterSpacing: 4.0,
                    color: AppTheme.textWhite,
                  ),
                ).animate().fadeIn(duration: 1.seconds).moveY(begin: 20, end: 0),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Your AI Muse. Always with you.',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGrey,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 1.seconds),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
