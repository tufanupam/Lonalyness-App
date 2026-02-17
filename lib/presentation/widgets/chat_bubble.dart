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
      padding: const EdgeInsets.only(bottom: 24), // More breathing room
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar (Optional, if we want it next to bubble)
          if (!_isUser) ...[
             // We can put a tiny avatar here if we want, but header has it.
             // Leaving empty for now to focus on content.
          ],

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                // Gradient for User, Dark Glass for AI
                gradient: _isUser
                    ? LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
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
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                    ],
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
                          color: _isUser ? Colors.white : Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.5,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                        code: TextStyle(
                          color: _isUser ? Colors.white : accentColor,
                          backgroundColor: Colors.black26, 
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        blockquote: TextStyle(
                           color: _isUser ? Colors.white70 : AppTheme.textMuted,
                           fontStyle: FontStyle.italic,
                        ),
                        strong: TextStyle(fontWeight: FontWeight.bold, color: _isUser ? Colors.white : Colors.white),
                      ),
                    ),

                  // Timestamp
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: _isUser ? Colors.white.withOpacity(0.7) : AppTheme.textGrey,
                      ),
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
