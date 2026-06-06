import '../../models/chat_card.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final List<ChatCard> cards;
  final bool isThinking;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.isUser,
    this.text = '',
    this.cards = const [],
    this.isThinking = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ChatError {
  final String type;
  final String title;
  final String message;
  final String? actionLabel;
  final String? secondaryLabel;

  const ChatError({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.secondaryLabel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatError &&
          type == other.type &&
          title == other.title &&
          message == other.message;

  @override
  int get hashCode => type.hashCode ^ title.hashCode ^ message.hashCode;
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final ChatError? chatError;
  final List<Map<String, dynamic>> sessions;
  final String? currentSessionId;
  final bool webSearchEnabled;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.chatError,
    this.sessions = const [],
    this.currentSessionId,
    this.webSearchEnabled = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    ChatError? chatError,
    bool clearChatError = false,
    List<Map<String, dynamic>>? sessions,
    String? currentSessionId,
    bool? webSearchEnabled,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      chatError: clearChatError ? null : (chatError ?? this.chatError),
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
    );
  }
}
