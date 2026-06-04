import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import '../../core/sse_stream_handler.dart';
import '../../models/chat_card.dart';
import '../../services/chat_stream_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<Object, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<ChatMessageSent>(_onSend);
    on<ChatStreamCancelled>(_onCancel);
    on<ChatSessionsLoadRequested>(_onLoadSessions);
    on<ChatSessionSwitchRequested>(_onSwitchSession);
    on<ChatNewSessionRequested>(_onNewSession);
    on<ChatWebSearchToggled>(_onToggleWebSearch);
  }

  final _api = ApiClient();
  final _streamService = ChatStreamService();
  bool _pendingNewSession = false;

  Future<void> _onSend(ChatMessageSent event, Emitter<ChatState> emit) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: event.message,
    );
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    final messages = [
      ...state.messages,
      userMsg,
      ChatMessage(id: aiMsgId, isUser: false, isThinking: true),
    ];
    emit(ChatState(
      messages: messages,
      isStreaming: true,
      sessions: state.sessions,
      currentSessionId: state.currentSessionId,
      webSearchEnabled: state.webSearchEnabled,
    ));

    final cards = <ChatCard>[];
    var retried = false;
    final isFirstSend = _pendingNewSession;
    _pendingNewSession = false;

    await for (final streamEvent in _streamService.sendMessage(event.message, newSession: isFirstSend, webSearch: event.webSearch)) {
      if (streamEvent is ChatStreamText) {
        final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
        if (idx == -1) continue;
        final msgs = List<ChatMessage>.from(state.messages);
        msgs[idx] = ChatMessage(
          id: aiMsgId,
          isUser: false,
          text: msgs[idx].text + streamEvent.content,
          cards: List<ChatCard>.from(cards),
          isThinking: false,
        );
        emit(ChatState(
          messages: msgs,
          isStreaming: true,
          sessions: state.sessions,
          currentSessionId: state.currentSessionId,
          webSearchEnabled: state.webSearchEnabled,
        ));
      } else if (streamEvent is ChatStreamCard) {
        cards.add(streamEvent.card);
        final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
        if (idx == -1) continue;
        final msgs = List<ChatMessage>.from(state.messages);
        msgs[idx] = ChatMessage(
          id: aiMsgId,
          isUser: false,
          text: msgs[idx].text,
          cards: List<ChatCard>.from(cards),
          isThinking: false,
        );
        emit(ChatState(
          messages: msgs,
          isStreaming: true,
          sessions: state.sessions,
          currentSessionId: state.currentSessionId,
          webSearchEnabled: state.webSearchEnabled,
        ));
      } else if (streamEvent is ChatStreamDone) {
        final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
        if (idx != -1) {
          final msgs = List<ChatMessage>.from(state.messages);
          msgs[idx] = ChatMessage(
            id: aiMsgId,
            isUser: false,
            text: msgs[idx].text,
            cards: List<ChatCard>.from(cards),
          );
          emit(ChatState(
            messages: msgs,
            isStreaming: false,
            sessions: state.sessions,
            currentSessionId: state.currentSessionId,
            webSearchEnabled: state.webSearchEnabled,
          ));
        }
      } else if (streamEvent is ChatStreamError) {
        if (streamEvent.message == 'auth_expired' && !retried) {
          retried = true;
          try {
            await _api.refreshAccessToken();
            await for (final retryEvent in _streamService.sendMessage(event.message, webSearch: event.webSearch)) {
              if (retryEvent is ChatStreamText) {
                final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
                if (idx == -1) continue;
                final msgs = List<ChatMessage>.from(state.messages);
                msgs[idx] = ChatMessage(
                  id: aiMsgId, isUser: false,
                  text: msgs[idx].text + retryEvent.content,
                  cards: List<ChatCard>.from(cards),
                  isThinking: false,
                );
                emit(ChatState(
                  messages: msgs, isStreaming: true,
                  sessions: state.sessions, currentSessionId: state.currentSessionId,
                  webSearchEnabled: state.webSearchEnabled,
                ));
              } else if (retryEvent is ChatStreamCard) {
                cards.add(retryEvent.card);
              } else if (retryEvent is ChatStreamDone) {
                final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
                if (idx != -1) {
                  final msgs = List<ChatMessage>.from(state.messages);
                  msgs[idx] = ChatMessage(
                    id: aiMsgId, isUser: false,
                    text: msgs[idx].text, cards: List<ChatCard>.from(cards),
                  );
                  emit(ChatState(
                    messages: msgs, isStreaming: false,
                    sessions: state.sessions, currentSessionId: state.currentSessionId,
                    webSearchEnabled: state.webSearchEnabled,
                  ));
                }
              } else if (retryEvent is ChatStreamError) {
                emit(state.copyWith(isStreaming: false, error: '\u767b\u5f55\u5df2\u8fc7\u671f\uff0c\u8bf7\u91cd\u65b0\u767b\u5f55'));
                return;
              }
            }
          } catch (_) {
            emit(state.copyWith(isStreaming: false, error: '\u767b\u5f55\u5df2\u8fc7\u671f\uff0c\u8bf7\u91cd\u65b0\u767b\u5f55'));
            return;
          }
        } else {
          emit(state.copyWith(isStreaming: false, error: streamEvent.message));
          return;
        }
      }
    }

    if (state.isStreaming) {
      emit(state.copyWith(isStreaming: false));
    }
  }

  void _onCancel(ChatStreamCancelled event, Emitter<ChatState> emit) {
    _streamService.cancel();
    emit(state.copyWith(isStreaming: false));
  }

  Future<void> _onLoadSessions(
    ChatSessionsLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final resp = await _api.get('/api/ai/chat/sessions');
      final sessions = (resp.data as List).cast<Map<String, dynamic>>();
      emit(state.copyWith(sessions: sessions));
    } catch (_) {}
  }

  Future<void> _onSwitchSession(
    ChatSessionSwitchRequested event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final resp = await _api.get('/api/ai/chat/${event.sessionId}/history');
      final history = resp.data as List;
      final messages = history.map((m) => ChatMessage(
        id: m['id'] as String,
        isUser: m['role'] == 'user',
        text: m['content'] as String,
        cards: ((m['tool_calls'] as Map<String, dynamic>?)?['cards'] as List?)
                ?.map((c) => ChatCard.fromJson(c as Map<String, dynamic>))
                .toList() ?? [],
      )).toList();
      emit(ChatState(
        messages: messages,
        currentSessionId: event.sessionId,
        sessions: state.sessions,
        webSearchEnabled: state.webSearchEnabled,
      ));
    } catch (_) {}
  }

  void _onNewSession(ChatNewSessionRequested event, Emitter<ChatState> emit) {
    _pendingNewSession = true;
    emit(ChatState(
      sessions: state.sessions,
      webSearchEnabled: state.webSearchEnabled,
    ));
  }

  void _onToggleWebSearch(ChatWebSearchToggled event, Emitter<ChatState> emit) {
    emit(state.copyWith(webSearchEnabled: !state.webSearchEnabled));
  }

  @override
  Future<void> close() {
    _streamService.cancel();
    return super.close();
  }
}
