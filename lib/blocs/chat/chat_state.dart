class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final List<Map<String, dynamic>> cards;
  final bool isThinking;

  const ChatMessage({
    required this.id,
    required this.isUser,
    this.text = '',
    this.cards = const [],
    this.isThinking = false,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
    );
  }
}
