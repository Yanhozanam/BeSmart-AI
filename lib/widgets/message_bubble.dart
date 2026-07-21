import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onRegenerate;
  final ValueChanged<bool>? onFeedback;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int index;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onFeedback,
    this.onEdit,
    this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    if (isUser) {
      return _buildUserMessage(context);
    }
    return _buildAiMessage(context);
  }

  Widget _buildUserMessage(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildUserAvatar(),
                      const SizedBox(width: 10),
                      Text(
                        'Message',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 8),
                  if (onEdit != null)
                    ListTile(
                      leading: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                      title: const Text(
                        'Edit',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      ),
                      dense: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        onEdit?.call();
                      },
                    ),
                  if (onDelete != null)
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: AppColors.errorText, size: 20),
                      title: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.errorText, fontSize: 15),
                      ),
                      dense: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete message?', style: TextStyle(color: AppColors.textPrimary)),
                            content: const Text('This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dCtx);
                                  onDelete?.call();
                                },
                                child: const Text('Delete', style: TextStyle(color: AppColors.errorText)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 56.0, right: 16.0, top: 8.0, bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: AppColors.userText,
                      fontSize: 13.0,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.0,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.userAvatarBg,
      child: const Icon(
        Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAiMessage(BuildContext context) {
    final displayText = message.isStreaming ? '${message.content}▌' : message.content;
    final parsedSpans = _parseBoldText(displayText);

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with mascot badge and acknowledgment
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _buildMascotBadge(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getAcknowledgment(message.content),
                          style: const TextStyle(
                            color: AppColors.textOnCard,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!message.isStreaming && onRegenerate != null) ...[
                        IconButton(
                          onPressed: onRegenerate,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Regenerate',
                        ),
                      ],
                    ],
                  ),
                ),
                // Body text with bold inline terms
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textOnCard,
                        fontSize: 13.0,
                        height: 1.55,
                      ),
                      children: parsedSpans,
                    ),
                  ),
                ),
                // Footer with timestamp and feedback
                if (!message.isStreaming)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildFeedbackButton(Icons.thumb_up_rounded, true),
                        const SizedBox(width: 8),
                        _buildFeedbackButton(Icons.thumb_down_rounded, false),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _copyToClipboard(context),
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Copy',
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

  Widget _buildMascotBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.mascotBadgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.menu_book_rounded, // Book/leaf glyph for study mascot
        size: 16,
        color: AppColors.mascotBadgeIcon,
      ),
    );
  }

  Widget _buildFeedbackButton(IconData icon, bool isPositive) {
    return GestureDetector(
      onTap: () => onFeedback?.call(isPositive),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.feedbackIcon,
      ),
    );
  }

  String _getAcknowledgment(String content) {
    // Simple acknowledgment based on content patterns
    final lower = content.toLowerCase().trim();
    if (lower.startsWith('no problem') ||
        lower.startsWith('you\'re welcome') ||
        lower.startsWith('sure') ||
        lower.startsWith('of course') ||
        lower.startsWith('absolutely') ||
        lower.startsWith('certainly') ||
        lower.startsWith('happy to') ||
        lower.startsWith('glad to')) {
      return content.split(' ').take(3).join(' ');
    }
    // Default acknowledgment
    return 'No problem!';
  }

  List<TextSpan> _parseBoldText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      // Add the bold part
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textOnCardSecondary,
        ),
      ));
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    // If no bold markers found, return plain text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}