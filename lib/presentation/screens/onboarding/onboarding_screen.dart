import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.deepPurple.withOpacity(0.2),
                ),
              ),
            ),
          ),
           Positioned(
            bottom: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentPink.withOpacity(0.15),
                ),
              ),
            ),
          ),

          // Content
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: const [
              _OnboardingStep(
                title: "Choose Your Muse",
                description:
                    "Select an AI personality that resonates with your soul. Each Muse has a unique voice and story.",
                imageIcon: Icons.person_search_rounded,
              ),
              _OnboardingStep(
                title: "Define the Bond",
                description:
                    "Friend, Fan, or Partner? You decide the nature of your relationship.",
                imageIcon: Icons.favorite_border_rounded,
              ),
              _OnboardingStep(
                title: "Always Connected",
                description:
                    "Enable notifications to receive daily voice notes and calls from your Muse.",
                imageIcon: Icons.notifications_none_rounded,
              ),
            ],
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicators
                Row(
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.accentPink
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next/Get Started Button
                GestureDetector(
                  onTap: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/login');
                    }
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      gradient: AppTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepPurple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentPage == 2 ? "Get Started" : "Next",
                      style: AppTheme.textTheme.labelLarge,
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

class _OnboardingStep extends StatelessWidget {
  final String title;
  final String description;
  final IconData imageIcon;

  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.imageIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon/Image Placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(imageIcon, size: 50, color: AppTheme.textWhite),
          ).animate().fadeIn(duration: 800.ms).moveY(begin: 30, end: 0),

          const SizedBox(height: 48),

          Text(
            title,
            style: AppTheme.textTheme.displayMedium,
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).moveX(begin: -20, end: 0),

          const SizedBox(height: 16),

          Text(
            description,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: AppTheme.textGrey,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms).moveX(begin: -20, end: 0),
        ],
      ),
    );
  }
}
