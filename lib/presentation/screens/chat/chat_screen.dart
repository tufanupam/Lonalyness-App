import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.personaId));
    final persona = ref.watch(personaByIdProvider(widget.personaId));

    // Fallback accent color
    Color accentColor = AppTheme.deepPurple;
    if (persona != null) {
      try {
         // Handle hex strings like "#RRGGBB" or "RRGGBB"
        String hex = persona.accentColor.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        accentColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack.withOpacity(0.8), // Glass effect
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            // Mini Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 1.5),
                image: persona != null ? DecorationImage(
                  image: AssetImage(persona.avatarPath),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: persona == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  persona?.name ?? 'AI Persona',
                  style: AppTheme.textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
                Text(
                  chatState.isLoading ? 'typing...' : 'Online',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: chatState.isLoading ? accentColor : AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ).animate(target: chatState.isLoading ? 1 : 0).fade(),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            onPressed: () => context.pushNamed('voiceCall', pathParameters: {'personaId': widget.personaId}),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0F1E), Color(0xFF050505)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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
                        padding: EdgeInsets.fromLTRB(
                            16, kToolbarHeight + 40, 16, 20), // Top padding for AppBar
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
                          return ChatBubble(
                            message: msg,
                            accentColor: accentColor,
                            personaName: persona?.name ?? 'AI',
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                        },
                      ),
              ),

              // ── Input Bar ──────────────────────────────────────
              _buildInputBar(accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String greeting, Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: accentColor,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            greeting,
            textAlign: TextAlign.center,
            style: AppTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textGrey,
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildInputBar(Color accentColor) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.6),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              // Voice message button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic_rounded, color: AppTheme.textGrey),
                  onPressed: () {
                    // TODO: Implement voice message recording
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Text input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSub),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Send button
              AnimatedSwitcher(
                duration: 200.ms,
                child: _showSendButton
                    ? GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.premiumGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.deepPurple.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      )
                    : Container(
                       width: 44,
                       height: 44,
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.05),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.favorite_border_rounded, color: AppTheme.textGrey, size: 22),
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
          CircleAvatar(
            radius: 3,
            backgroundColor: accentColor,
          ).animate(onPlay: (c) => c.repeat()).scale(delay: 0.ms, duration: 600.ms),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 3,
            backgroundColor: accentColor,
          ).animate(onPlay: (c) => c.repeat()).scale(delay: 200.ms, duration: 600.ms),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 3,
            backgroundColor: accentColor,
          ).animate(onPlay: (c) => c.repeat()).scale(delay: 400.ms, duration: 600.ms),
        ],
      ),
    );
  }
}
