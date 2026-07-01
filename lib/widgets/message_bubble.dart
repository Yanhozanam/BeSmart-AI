import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    if (isUser) {
      return _buildUserBubble();
    }
    return _buildAiBubble(context);
  }

  Widget _buildUserBubble() {
    return Padding(
      padding: const EdgeInsets.only(left: 64.0, right: 16.0, top: 6.0, bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: const BoxDecoration(
                color: Color(0xFF075E54),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 15.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.0),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    final displayText = message.isStreaming ? '${message.content}▌' : message.content;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 64.0, top: 6.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(false),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BeSmartAI',
                    style: TextStyle(
                      color: Color(0xFF00A884),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11.0,
                        ),
                      ),
                      if (!message.isStreaming) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _copyToClipboard(context),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF1F2C33),
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? const Color(0xFF128C7E) : const Color(0xFF00A884),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
