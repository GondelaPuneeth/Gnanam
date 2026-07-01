class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });
}