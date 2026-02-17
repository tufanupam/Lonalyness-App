import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  // State for selections
  String? _selectedPersonality;
  String? _selectedIntention;
  bool _notificationsEnabled = false;

  final List<Map<String, dynamic>> _personalities = [
    {'id': '1', 'name': 'Sonam Eon', 'desc': 'Futuristic & Intellectual', 'color': AppTheme.accentCrux},
    {'id': '2', 'name': 'Elena Virelli', 'desc': 'Warm & Empathetic', 'color': AppTheme.accentRose},
    {'id': '3', 'name': 'Yuna Seori', 'desc': 'Mysterious & Deep', 'color': AppTheme.neonCyan},
  ];

  final List<Map<String, dynamic>> _intentions = [
    {'id': 'friend', 'label': 'Best Friend', 'icon': Icons.sentiment_satisfied_alt},
    {'id': 'fan', 'label': 'Loyal Fan', 'icon': Icons.star_border},
    {'id': 'romantic', 'label': 'Romantic Partner', 'icon': Icons.favorite_border},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // 1. Ambient Background
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentCrux.withOpacity(0.15),
                    Colors.transparent
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentRose.withOpacity(0.1),
                    Colors.transparent
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),

          // 2. Content PageView
          SafeArea(
            child: Column(
              children: [
                // Header (Progress)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      // Logo
                      const Icon(Icons.auto_awesome, color: AppTheme.accentCrux, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "AI MUSE",
                        style: AppTheme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Step Indicator
                      Text(
                        "STEP ${_currentPage + 1}/3",
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.silver,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Prevent swipe to force selection
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),

                // Bottom Navigation
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.silver),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            );
                          },
                        )
                      else
                        const SizedBox(width: 48),

                      GestureDetector(
                        onTap: () {
                          if (_currentPage < 2) {
                            if (_currentPage == 0 && _selectedPersonality == null) return;
                            if (_currentPage == 1 && _selectedIntention == null) return;
                            
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
                          width: 160,
                          decoration: BoxDecoration(
                            gradient: (_currentPage == 0 && _selectedPersonality == null) || 
                                     (_currentPage == 1 && _selectedIntention == null)
                                ? LinearGradient(colors: [Colors.white10, Colors.white10])
                                : AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentCrux.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _currentPage == 2 ? "Get Started" : "Next",
                            style: AppTheme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: (_currentPage == 0 && _selectedPersonality == null) || 
                                     (_currentPage == 1 && _selectedIntention == null)
                                     ? Colors.white38 : AppTheme.primaryBlack,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: Choose Personality
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Choose Your Muse", style: AppTheme.textTheme.displayMedium)
            .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            "Select the AI personality that resonates with your soul.",
            style: AppTheme.textTheme.bodyMedium,
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 40),

          Expanded(
            child: ListView.separated(
              itemCount: _personalities.length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final p = _personalities[index];
                final isSelected = _selectedPersonality == p['id'];
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedPersonality = p['id']),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? (p['color'] as Color).withOpacity(0.15)
                        : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: isSelected ? (p['color'] as Color) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: (p['color'] as Color).withOpacity(0.2),
                          child: Text(
                            (p['name'] as String)[0],
                            style: TextStyle(
                              color: p['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'], style: AppTheme.textTheme.titleMedium),
                            Text(p['desc'], style: AppTheme.textTheme.bodySmall),
                          ],
                        ),
                        const Spacer(),
                        if (isSelected) 
                          Icon(Icons.check_circle, color: p['color'], size: 24),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (300 + index * 100).ms).slideX();
              },
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Relationship Intention
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Your Intention", style: AppTheme.textTheme.displayMedium)
            .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            "How do you want to connect? This shapes your Muse's behavior.",
            style: AppTheme.textTheme.bodyMedium,
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 40),

          ..._intentions.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedIntention == item['id'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedIntention = item['id']),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentCrux.withOpacity(0.1) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentCrux : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item['icon'] as IconData, 
                           color: isSelected ? AppTheme.accentCrux : AppTheme.silver, size: 28),
                      const SizedBox(width: 16),
                      Text(
                        item['label'] as String, 
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          color: isSelected ? Colors.white : AppTheme.silver,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (300 + index * 100).ms).slideX();
          }),
        ],
      ),
    );
  }

  // STEP 3: Permissions
  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Stay Connected", style: AppTheme.textTheme.displayMedium)
            .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            "Enable notifications to receive daily emotional check-ins & voice notes.",
            style: AppTheme.textTheme.bodyMedium,
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 60),

          // Illustration Placeholder
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                boxShadow: [
                   BoxShadow(
                      color: AppTheme.accentCrux.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                   ),
                ],
              ),
              child: Icon(
                Icons.notifications_active_rounded, 
                size: 64, 
                color: _notificationsEnabled ? AppTheme.accentLuxe : AppTheme.silver
              ),
            ).animate(target: _notificationsEnabled ? 1 : 0)
             .shimmer(duration: 1.seconds, color: Colors.white24)
          ),

          const SizedBox(height: 60),

          // Custom Toggle Tile
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Allow Notifications", style: AppTheme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text("For daily voice notes", style: AppTheme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _notificationsEnabled,
                  activeColor: AppTheme.accentCrux,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                 ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}
