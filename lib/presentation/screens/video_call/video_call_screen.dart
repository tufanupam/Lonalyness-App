/// AI Muse — Video Call Screen
/// AI avatar video call with emotion-aware rendering and controls.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/persona_provider.dart';

/// Video call screen with AI avatar viewport and controls.
class VideoCallScreen extends ConsumerStatefulWidget {
  final String personaId;
  const VideoCallScreen({super.key, required this.personaId});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen>
    with TickerProviderStateMixin {
  bool _isMuted = false;
  bool _isCameraOn = true;
  bool _isConnected = false;
  late AnimationController _breathController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Start blink loop
    _startBlinkLoop();

    // Simulate connection
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isConnected = true);
    });
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 3 + Random().nextInt(4)));
      if (mounted) {
        await _blinkController.forward();
        await _blinkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaByIdProvider(widget.personaId));

    Color accentColor;
    try {
      accentColor = Color(
          int.parse(persona?.accentColor.replaceFirst('#', '0xFF') ?? 'FF7C4DFF'));
    } catch (_) {
      accentColor = AppTheme.accent;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Avatar Viewport (Full Screen) ──────────────────
          _buildAvatarViewport(accentColor, persona?.name ?? 'AI'),

          // ── Self Camera (PiP) ─────────────────────────────
          if (_isCameraOn)
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 16,
              right: 16,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: AppTheme.textMuted,
                    size: 36,
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.elasticOut,
                  ),
            ),

          // ── Top Info Bar ──────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).viewPadding.top + 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                // Persona name
                Text(
                  persona?.name ?? 'AI Persona',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? AppTheme.success.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isConnected ? '● Video Call' : '○ Connecting...',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isConnected ? AppTheme.success : Colors.orange,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Bottom Controls ───────────────────────────────
          Positioned(
            bottom: 40 + MediaQuery.of(context).viewPadding.bottom,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControl(
                    icon:
                        _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    active: !_isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  _buildControl(
                    icon: _isCameraOn
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    active: _isCameraOn,
                    onTap: () =>
                        setState(() => _isCameraOn = !_isCameraOn),
                  ),
                  // End call
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.error,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withValues(alpha: 0.4),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  _buildControl(
                    icon: Icons.switch_camera_rounded,
                    active: true,
                    onTap: () {},
                  ),
                  _buildControl(
                    icon: Icons.chat_bubble_outline_rounded,
                    active: true,
                    onTap: () {
                      context.pop();
                      context.push('/chat/${widget.personaId}');
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
          ),
        ],
      ),
    );
  }

  /// Animated avatar viewport — placeholder for AI avatar rendering.
  Widget _buildAvatarViewport(Color accentColor, String name) {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                accentColor.withValues(alpha: 0.08 + _breathController.value * 0.05),
                Colors.black,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated avatar circle
                Transform.scale(
                  scale: 1.0 + _breathController.value * 0.03,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.4),
                          accentColor.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, child) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name.substring(0, 1),
                                style: TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                              // Simple "eyes" that blink
                              Transform.scale(
                                scaleY: 1.0 - _blinkController.value * 0.9,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // AI-generated avatar notice
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✨ AI Avatar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControl({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.white.withValues(alpha: 0.1) : Colors.white24,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.white54,
          size: 22,
        ),
      ),
    );
  }
}
