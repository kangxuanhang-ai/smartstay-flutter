import 'package:flutter/material.dart';
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
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ChatError({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? error;
  final ChatError? chatError;
  final List<Map<String, dynamic>> sessions;
  final String? currentSessionId;
  final bool webSearchEnabled;
  final bool isRecording;
  final int recordingDuration;
  final bool isTranscribing;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
    this.chatError,
    this.sessions = const [],
    this.currentSessionId,
    this.webSearchEnabled = false,
    this.isRecording = false,
    this.recordingDuration = 0,
    this.isTranscribing = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? error,
    ChatError? chatError,
    bool clearChatError = false,
    List<Map<String, dynamic>>? sessions,
    String? currentSessionId,
    bool? webSearchEnabled,
    bool? isRecording,
    int? recordingDuration,
    bool? isTranscribing,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      chatError: clearChatError ? null : (chatError ?? this.chatError),
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      isTranscribing: isTranscribing ?? this.isTranscribing,
    );
  }
}
