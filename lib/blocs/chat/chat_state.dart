import '../../models/chat_card.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final List<ChatCard> cards;
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
  final List<Map<String, dynamic>> sessions;
  final String? currentSessionId;
  final bool webSearchEnabled;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
    this.sessions = const [],
    this.currentSessionId,
    this.webSearchEnabled = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? error,
    List<Map<String, dynamic>>? sessions,
    String? currentSessionId,
    bool? webSearchEnabled,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
    );
  }
}
