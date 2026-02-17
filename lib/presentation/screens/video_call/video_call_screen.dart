import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/persona_provider.dart';
import '../../../data/services/signaling_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Video call screen with AI avatar viewport and controls.
class VideoCallScreen extends ConsumerStatefulWidget {
  final String personaId;
  const VideoCallScreen({super.key, required this.personaId});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> with TickerProviderStateMixin {
  bool _isMuted = false;
  bool _isCameraOn = true;
  bool _isConnected = false;
  late AnimationController _breathController;

  final SignalingService _signaling = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
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
      await _signaling.openUserMedia(_localRenderer, _remoteRenderer, audioOnly: false);
      
      _roomId = await _signaling.createRoom(_signaling.localStream!);
      debugPrint("Video Call Room Created: $_roomId");
    } catch (e) {
      debugPrint("Video Call Initialization Error: $e");
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signaling.hangUp(_localRenderer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaByIdProvider(widget.personaId));
    
    // Fallback accent color (using safer parsing or default)
    Color accentColor = AppTheme.accentCyan; 
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
          // ── 1. Avatar Viewport (Simulated Video Feed) ──────────────────
          if (persona != null)
             AnimatedBuilder(
               animation: _breathController,
               builder: (context, child) {
                 return Transform.scale(
                   scale: 1.02 + (_breathController.value * 0.02), // Very subtle movement
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

          // ── 2. Cinematic Gradient Overlay ─────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black54, 
                  Colors.transparent, 
                  Colors.transparent, 
                  Colors.black87
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
          
          // ── 2.5 HUD Elements (Futuristic) ─────────────────────────────
          if (_isConnected)
             Positioned.fill(
               child: IgnorePointer(
                 child: Stack(
                   children: [
                     // Focus Bracket (Center Face)
                     Center(
                       child: Container(
                         width: 250,
                         height: 250,
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                           borderRadius: BorderRadius.circular(20),
                         ),
                       ).animate().scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 1.seconds, curve: Curves.easeOut),
                     ),
                     // Crosshairs
                     Center(child: Container(width: 20, height: 1, color: Colors.white.withOpacity(0.2))),
                     Center(child: Container(width: 1, height: 20, color: Colors.white.withOpacity(0.2))),
                   ],
                 ),
               ),
             ),

          // ── 3. Self Camera (PiP) ──────────────────────────────────────
          if (_isCameraOn)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                       Container(color: Color(0xFF1C1C1E)), // Placeholder for camera
                       const Center(
                         child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 32),
                       ),
                       // User Name Label
                       Align(
                         alignment: Alignment.bottomCenter,
                         child: Container(
                           width: double.infinity,
                           color: Colors.black54,
                           padding: const EdgeInsets.symmetric(vertical: 4),
                           child: const Text(
                             "You",
                             textAlign: TextAlign.center,
                             style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
              ).animate().scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 600.ms),
            ),

          // ── 4. UI Controls ────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                       // Back Button
                       GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          ),
                       ),
                       const SizedBox(width: 12),
                       // Name & Status using GlassPill style
                       ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.white.withOpacity(0.1),
                              child: Row(
                                children: [
                                  Text(
                                    persona?.name ?? 'AI Muse',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 1, height: 12, color: Colors.white24),
                                  const SizedBox(width: 8),
                                  // REC indicator
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: _isConnected ? AppTheme.error : AppTheme.accentLuxe,
                                      shape: BoxShape.circle,
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.2, end: 1.0, duration: 1.seconds),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isConnected ? "REC 00:12" : "Connecting",
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                       ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GlassControl(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        isActive: !_isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      const SizedBox(width: 20),
                      _GlassControl(
                        icon: _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        isActive: _isCameraOn,
                        onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                      ),
                      const SizedBox(width: 20),
                      _EndCallButton(onTap: () => context.pop()),
                      const SizedBox(width: 20),
                      _GlassControl(
                        icon: Icons.chat_bubble_rounded,
                        isActive: true, // Always active to switch
                        isSecondary: true,
                        onTap: () {
                           context.pop();
                           context.push('/chat/${widget.personaId}');
                        },
                      ),
                      const SizedBox(width: 20),
                      _GlassControl(
                        icon: Icons.flip_camera_ios_rounded,
                        isActive: true,
                         isSecondary: true,
                        onTap: () {}, // Switch camera
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

class _GlassControl extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isSecondary;
  final VoidCallback onTap;

  const _GlassControl({
    required this.icon,
    required this.isActive,
    this.isSecondary = false,
    required this.onTap,
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive 
                ? (isSecondary ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2)) 
                : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white54,
              size: 24,
            ),
          ),
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
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 1.seconds),
    );
  }
}
