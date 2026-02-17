import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/message_entity.dart';

/// A styled chat bubble for user and AI messages.
class ChatBubble extends StatelessWidget {
  final MessageEntity message;
  final Color accentColor;
  final String personaName;

  const ChatBubble({
    super.key,
    required this.message,
    this.accentColor = AppTheme.deepPurple,
    this.personaName = 'AI',
  });

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                // Gradient for User, Dark Card for AI
                gradient: _isUser
                    ? AppTheme.premiumGradient
                    : null,
                color: _isUser
                    ? null
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(_isUser ? 24 : 4),
                  bottomRight: Radius.circular(_isUser ? 4 : 24),
                ),
                border: Border.all(
                  color: _isUser
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: _isUser
                    ? [
                        BoxShadow(
                          color: AppTheme.deepPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Message content
                  if (message.content.isNotEmpty)
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          height: 1.5,
                          fontFamily: 'Inter',
                        ),
                        code: TextStyle(
                          color: accentColor,
                          backgroundColor: Colors.black26, 
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        strong: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                        em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
                      ),
                    ),

                  // Timestamp
                  const SizedBox(height: 6),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
