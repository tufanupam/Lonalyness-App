import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/persona_provider.dart';

/// Voice call screen with 'FaceTime 2026' aesthetic.
class VoiceCallScreen extends ConsumerStatefulWidget {
  final String personaId;
  const VoiceCallScreen({super.key, required this.personaId});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with TickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Simulate connection
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isConnected = true);
    });
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaByIdProvider(widget.personaId));
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Realistic Image
          if (persona != null)
            Image.asset(
              persona.avatarPath,
              fit: BoxFit.cover,
            ).animate(target: _isConnected ? 0 : 1).blur(
              begin: const Offset(0, 0),
              end: const Offset(20, 20),
              duration: 800.ms,
            ),
          
          // 2. Cinematic Letterbox / Gradient
          Column(
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),

          // 3. UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Header (Status)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: Center(
                    child: _GlassPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Container(
                            width: 6, 
                            height: 6, 
                            decoration: BoxDecoration(
                              color: _isConnected ? AppTheme.success : AppTheme.accentLuxe, 
                              shape: BoxShape.circle
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnected ? 'HD Audio • 24ms' : 'Connecting...',
                            style: AppTheme.textTheme.labelLarge?.copyWith(
                              fontSize: 12, 
                              color: Colors.white70
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Subtitles (Minimal)
                if (_isConnected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "I can see the city lights reflecting in your eyes...",
                      textAlign: TextAlign.center,
                      style: AppTheme.textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ).animate().fadeIn(duration: 1.seconds),
                  ),

                const SizedBox(height: 48),

                // Active Waveform (Subtle)
                if (_isConnected)
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(8, (index) {
                         return AnimatedBuilder(
                           animation: _waveformController,
                           builder: (context, child) {
                             // Random-ish smooth movement
                             double noise = (index % 3 == 0) ? 0.5 : 1.0;
                             double height = 4 + 16 * 
                               (0.5 + 0.5 * (
                                 _waveformController.value * 6.28 + index
                               ).sin()) * noise;
                             return Container(
                               width: 4,
                               height: height,
                               margin: const EdgeInsets.symmetric(horizontal: 3),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.8),
                                 borderRadius: BorderRadius.circular(2),
                               ),
                             );
                           },
                         );
                      }),
                    ),
                  ),

                const SizedBox(height: 48),

                // Controls (Minimal Glass Row)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleControl(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        isActive: _isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      const SizedBox(width: 24),
                      _EndCallButton(onTap: () => context.pop()),
                      const SizedBox(width: 24),
                      _CircleControl(
                        icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        isActive: _isSpeakerOn,
                        onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
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
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white.withOpacity(0.1),
          child: child,
        ),
      ),
    );
  }
}

class _CircleControl extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CircleControl({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentRose, // Professional Red
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
