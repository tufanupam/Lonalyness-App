import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/persona_provider.dart';
import '../../../data/services/signaling_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  late AnimationController _breathingController;

  final SignalingService _signaling = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _initCall();
  }

  Future<void> _initCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      if (mounted) setState(() => _isConnected = true);
    });

    try {
      await _signaling.openUserMedia(_localRenderer, _remoteRenderer, audioOnly: true);
      
      // In a real app, you'd either create or join based on navigation context.
      // For this demo, we "Create" a room.
      _roomId = await _signaling.createRoom(_signaling.localStream!);
      debugPrint("Call Room Created: $_roomId");
    } catch (e) {
      debugPrint("Call Initialization Error: $e");
    }
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _breathingController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signaling.hangUp(_localRenderer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaByIdProvider(widget.personaId));
    
    // Fallback accent color
    Color accentColor = AppTheme.accentCrux;
    if (persona != null) {
      try {
        String hex = persona.accentColor.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        accentColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Realistic Image with Breathing Effect
          if (persona != null)
            AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_breathingController.value * 0.05), // Subtle zoom breathing
                  child: Image.network(
                    persona.avatarPath.isNotEmpty ? persona.avatarPath : 'https://placehold.co/800x1200/png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryBlack),
                  ),
                );
              },
            ).animate(target: _isConnected ? 0 : 1).blur(
              begin: const Offset(0, 0),
              end: const Offset(20, 20),
              duration: 800.ms,
            ),
          
          // 2. Cinematic Letterbox / Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6), 
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.9)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // 3. UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Header (Status)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: _GlassPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           AnimatedContainer(
                            duration: 500.ms,
                            width: 8, 
                            height: 8, 
                            decoration: BoxDecoration(
                              color: _isConnected ? AppTheme.success : AppTheme.accentLuxe, 
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isConnected ? AppTheme.success : AppTheme.accentLuxe).withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isConnected ? 'HD Audio • 04:20' : 'Connecting securely...',
                            style: AppTheme.textTheme.labelLarge?.copyWith(
                              fontSize: 12, 
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Subtitles / Connection Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedSwitcher(
                    duration: 500.ms,
                    child: _isConnected
                      ? Text(
                          "\"I was just thinking about you... how's your day going?\"",
                          textAlign: TextAlign.center,
                          key: const ValueKey('subs'),
                          style: AppTheme.textTheme.headlineSmall?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 20),
                            ]
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1)
                      : Text(
                          persona?.name ?? 'AI Muse',
                          key: const ValueKey('name'),
                          style: AppTheme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0),
                  ),
                ),

                const SizedBox(height: 40),

                // Active Waveform (Dynamic)
                if (_isConnected)
                  SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(12, (index) {
                         return AnimatedBuilder(
                           animation: _waveformController,
                           builder: (context, child) {
                             // Complex wave math for organic look
                             double t = _waveformController.value * 2 * pi;
                             double noise = (index % 2 == 0) ? 0.7 : 1.2;
                             double height = 8 + 32 * 
                               (0.5 + 0.5 * sin(t + index * 0.5)) * noise;
                             
                             return Container(
                               width: 4,
                               height: height,
                               margin: const EdgeInsets.symmetric(horizontal: 4),
                               decoration: BoxDecoration(
                                 color: accentColor.withOpacity(0.8),
                                 borderRadius: BorderRadius.circular(2),
                                 boxShadow: [
                                   BoxShadow(
                                     color: accentColor.withOpacity(0.5),
                                     blurRadius: 12,
                                     spreadRadius: 1,
                                   )
                                 ]
                               ),
                             );
                           },
                         );
                      }),
                    ),
                  ).animate().fadeIn(),

                const SizedBox(height: 60),

                // Controls (Glassmorphic)
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       _ControlCircle(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        isActive: !_isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      const SizedBox(width: 32),
                      _EndCallButton(onTap: () => context.pop()),
                      const SizedBox(width: 32),
                       _ControlCircle(
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
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ControlCircle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlCircle({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
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
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.error.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 1.seconds),
    );
  }
}
