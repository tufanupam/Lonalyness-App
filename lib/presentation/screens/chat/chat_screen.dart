import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/entities/message_entity.dart';
import '../../providers/chat_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/chat_bubble.dart';

/// Main chat interface for conversing with an AI persona.
class ChatScreen extends ConsumerStatefulWidget {
  final String personaId;
  const ChatScreen({super.key, required this.personaId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() => _showSendButton = _messageController.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider(widget.personaId).notifier).sendMessage(text);
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(100.ms, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper to parse hex color safely
  Color _getAccentColor(String? hex) {
    if (hex == null) return AppTheme.accentCrux;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.accentCrux;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.personaId));
    final persona = ref.watch(personaByIdProvider(widget.personaId));
    final accentColor = _getAccentColor(persona?.accentColor);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AppTheme.primaryBlack.withOpacity(0.5),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            // Mini Avatar with Status Dot
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                    image: persona != null ? DecorationImage(
                      image: NetworkImage(persona.avatarPath.isNotEmpty ? persona.avatarPath : 'https://placehold.co/200/png'),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: persona == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan, // Online color
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBlack, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accentCyan.withOpacity(0.5), blurRadius: 4),
                      ]
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  persona?.name ?? 'AI Muse',
                  style: AppTheme.textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
                AnimatedSwitcher(
                  duration: 300.ms,
                  child: chatState.isLoading 
                    ? Text(
                        'typing...',
                        key: const ValueKey('typing'),
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: accentColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        'Online',
                        key: const ValueKey('online'),
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            onPressed: () => context.pushNamed('videoCall', pathParameters: {'personaId': widget.personaId}),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            onPressed: () => context.pushNamed('voiceCall', pathParameters: {'personaId': widget.personaId}),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient/Image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0F1E),
                    Color(0xFF000000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Opacity(
                opacity: 0.2, // Subtle texture
                child: Image.network(
                  "https://www.transparenttextures.com/patterns/cubes.png", // Or local asset
                  repeat: ImageRepeat.repeat,
                  errorBuilder: (_,__,___) => const SizedBox(),
                ),
              ),
            ),
          ),

          Column(
            children: [
              // ── Messages List ──────────────────────────────────
              Expanded(
                child: chatState.messages.isEmpty && !chatState.isLoading
                    ? _buildEmptyState(persona?.greetings['en'] ?? 'Say hello!', accentColor)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                            16, kToolbarHeight + 40, 16, 120), // Top padding for AppBar, Bottom for Input
                        itemCount: chatState.messages.length +
                            (chatState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Typing indicator bubble
                          if (index == chatState.messages.length &&
                              chatState.isLoading) {
                            return Align(
                                alignment: Alignment.centerLeft,
                                child: _TypingBubble(accentColor: accentColor)
                            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
                          }

                          final msg = chatState.messages[index];
                          // Group messages visually (simplified for now)
                          return ChatBubble(
                            message: msg,
                            accentColor: accentColor,
                            personaName: persona?.name ?? 'AI',
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                        },
                      ),
              ),
            ],
          ),
          
          // ── Floating Input Bar ──────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildInputBar(accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String greeting, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: accentColor,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              "Start a conversation",
              style: AppTheme.textTheme.headlineMedium,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              "\"$greeting\"",
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(Color accentColor) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom, // Use padding.bottom instead of viewPadding for safe area
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack.withOpacity(0.8),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Voice/Attachment Button
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: AppTheme.textSecondary),
                  onPressed: () {
                    // TODO: Attachments
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Text Input Capsule
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          style: AppTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                         padding: EdgeInsets.zero,
                         constraints: const BoxConstraints(),
                         icon: const Icon(Icons.mic_none_rounded, color: AppTheme.textMuted, size: 20),
                         onPressed: () {},
                      ),
                      const SizedBox(width: 12), // Padding right
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Send Button
              AnimatedSwitcher(
                duration: 200.ms,
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: _showSendButton
                    ? GestureDetector( // Active Send Button
                        key: const ValueKey('send_active'),
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [accentColor, accentColor.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      )
                    : Container( // Inactive (Placeholder/Voice)
                       key: const ValueKey('send_inactive'),
                       width: 44,
                       height: 44,
                       margin: const EdgeInsets.only(bottom: 2),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.08),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24), // Voice mode by default?
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final Color accentColor;
  const _TypingBubble({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: accentColor, delay: 0),
          const SizedBox(width: 4),
          _Dot(color: accentColor, delay: 200),
          const SizedBox(width: 4),
          _Dot(color: accentColor, delay: 400),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final int delay;
  const _Dot({required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(delay: delay.ms, duration: 600.ms, begin: const Offset(0.7, 0.7), end: const Offset(1.2, 1.2))
     .fade(begin: 0.5, end: 1.0);
  }
}
