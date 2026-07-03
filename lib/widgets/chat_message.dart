import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gnanam/inference/chat_controller.dart';
import 'package:gnanam/widgets/custom_markdown.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onRegenerate;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.onRegenerate,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  bool _showTimestamp = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showTimestamp = !_showTimestamp;
        });
      },
      onLongPress: _showMessageOptions,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.message.isUser ? 60 : 16,
          8,
          widget.message.isUser ? 16 : 60,
          8,
        ),
        child: Column(
          crossAxisAlignment:
              widget.message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!widget.message.isUser)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMessageContent(),
                  ),
                ],
              )
            else
              _buildMessageContent(),
            if (_showTimestamp)
              Padding(
                padding: EdgeInsets.only(
                  left: widget.message.isUser ? 0 : 44,
                  top: 4,
                ),
                child: Text(
                  _formatTime(widget.message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(widget.message.isUser ? 18 : 4),
          bottomRight: Radius.circular(widget.message.isUser ? 4 : 18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.message.isStreaming
            ? _buildStreamingMessage()
            : CustomMarkdownWidget(
                data: widget.message.content,
                textColor: widget.message.isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStreamingMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: CustomMarkdownWidget(data: widget.message.content),
        ),
        const SizedBox(width: 4),
        Text(
          '▍',
          style: TextStyle(
            color: widget.message.isUser
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ).animate().fadeIn(
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy_outlined),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle copy
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_outlined),
                title: const Text('Regenerate'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onRegenerate();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle report
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle share
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}