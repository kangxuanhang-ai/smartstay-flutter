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
  final bool isRecording;
  final bool isTranscribing;
  final int recordingDuration;
  final String? transcribedText;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
    this.sessions = const [],
    this.currentSessionId,
    this.isRecording = false,
    this.isTranscribing = false,
    this.recordingDuration = 0,
    this.transcribedText,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? error,
    List<Map<String, dynamic>>? sessions,
    String? currentSessionId,
    bool? isRecording,
    bool? isTranscribing,
    int? recordingDuration,
    String? transcribedText,
    bool clearTranscribedText = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isRecording: isRecording ?? this.isRecording,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      transcribedText:
          clearTranscribedText ? null : (transcribedText ?? this.transcribedText),
    );
  }
}
