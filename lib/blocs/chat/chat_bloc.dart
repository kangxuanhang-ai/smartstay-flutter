import 'dart:async';
import 'dart:io';
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
    on<ChatRegenerate>(_onRegenerate);
    on<ChatErrorDismissed>(_onDismissError);
  }

  final _api = ApiClient();
  final _streamService = ChatStreamService();
  bool _pendingNewSession = false;

  // ── Error Classification ──
  ChatError _classifyError(Object error, [int? statusCode]) {
    if (error is SocketException || error is HttpException) {
      return ChatError(
        type: 'network',
        title: '网络不可用',
        message: '请检查网络连接后重试',
        actionLabel: '重新连接',
      );
    }
    if (statusCode == 401) {
      return ChatError(
        type: 'auth',
        title: '登录已过期',
        message: '请重新登录以继续使用',
        actionLabel: '重新登录',
      );
    }
    if (statusCode == 403) {
      return ChatError(
        type: 'forbidden',
        title: '请先办理入住',
        message: '入住后即可使用 AI 管家服务',
        actionLabel: '前往前台',
      );
    }
    if (statusCode == 500 || statusCode == 502 || statusCode == 503 ||
        error is TimeoutException) {
      return ChatError(
        type: 'server',
        title: 'AI 暂时不可用',
        message: '服务繁忙，请稍后再试',
        actionLabel: '重试',
        secondaryLabel: '联系前台',
      );
    }
    return ChatError(
      type: 'server',
      title: '发生错误',
      message: error.toString(),
      actionLabel: '重试',
    );
  }

  int? _extractStatusCode(Object error) {
    if (error.toString().contains('401')) return 401;
    if (error.toString().contains('403')) return 403;
    if (error.toString().contains('500')) return 500;
    if (error.toString().contains('502')) return 502;
    if (error.toString().contains('503')) return 503;
    return null;
  }

  // ── Send Message ──
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

    try {
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
                  // Remove thinking message, add error
                  final msgs = List<ChatMessage>.from(state.messages)
                    ..removeWhere((m) => m.id == aiMsgId);
                  emit(ChatState(
                    messages: msgs,
                    isStreaming: false,
                    chatError: const ChatError(
                      type: 'auth', title: '登录已过期',
                      message: '请重新登录以继续使用', actionLabel: '重新登录',
                    ),
                    sessions: state.sessions, currentSessionId: state.currentSessionId,
                    webSearchEnabled: state.webSearchEnabled,
                  ));
                  return;
                }
              }
            } catch (e) {
              final msgs = List<ChatMessage>.from(state.messages)
                ..removeWhere((m) => m.id == aiMsgId);
              emit(ChatState(
                messages: msgs,
                isStreaming: false,
                chatError: const ChatError(
                  type: 'auth', title: '登录已过期',
                  message: '请重新登录以继续使用', actionLabel: '重新登录',
                ),
                sessions: state.sessions, currentSessionId: state.currentSessionId,
                webSearchEnabled: state.webSearchEnabled,
              ));
              return;
            }
          } else {
            // Non-auth error or already retried
            final msgs = List<ChatMessage>.from(state.messages)
              ..removeWhere((m) => m.id == aiMsgId);
            final statusCode = _extractStatusCode(streamEvent.message);
            final chatError = _classifyError(
              streamEvent.message is Exception ? streamEvent.message as Exception : Exception(streamEvent.message.toString()),
              statusCode,
            );
            emit(ChatState(
              messages: msgs,
              isStreaming: false,
              chatError: chatError,
              sessions: state.sessions, currentSessionId: state.currentSessionId,
              webSearchEnabled: state.webSearchEnabled,
            ));
            return;
          }
        }
      }
    } catch (e) {
      // Network or other exceptions
      final msgs = List<ChatMessage>.from(state.messages)
        ..removeWhere((m) => m.id == aiMsgId);
      final statusCode = _extractStatusCode(e);
      final chatError = _classifyError(e, statusCode);
      emit(ChatState(
        messages: msgs,
        isStreaming: false,
        chatError: chatError,
        sessions: state.sessions, currentSessionId: state.currentSessionId,
        webSearchEnabled: state.webSearchEnabled,
      ));
      return;
    }

    if (state.isStreaming) {
      emit(state.copyWith(isStreaming: false));
    }
  }

  // ── Cancel ──
  void _onCancel(ChatStreamCancelled event, Emitter<ChatState> emit) {
    _streamService.cancel();
    emit(state.copyWith(isStreaming: false));
  }

  // ── Sessions ──
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

  // ── Regenerate ──
  void _onRegenerate(ChatRegenerate event, Emitter<ChatState> emit) {
    if (state.isStreaming) return;
    if (state.messages.isEmpty) return;

    // Find last AI message
    final lastAiIdx = state.messages.lastIndexWhere((m) => !m.isUser);
    if (lastAiIdx == -1) return;

    // Find the user message before it
    final userMsgIdx = state.messages.lastIndexWhere((m) => m.isUser, lastAiIdx);
    if (userMsgIdx == -1) return;

    final userText = state.messages[userMsgIdx].text;

    // Remove the last AI message
    final msgs = List<ChatMessage>.from(state.messages)
      ..removeAt(lastAiIdx);

    emit(ChatState(
      messages: msgs,
      sessions: state.sessions,
      currentSessionId: state.currentSessionId,
      webSearchEnabled: state.webSearchEnabled,
    ));

    // Re-send the same message
    add(ChatMessageSent(userText, webSearch: state.webSearchEnabled));
  }

  // ── Dismiss Error ──
  void _onDismissError(ChatErrorDismissed event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearChatError: true));
  }

  @override
  Future<void> close() {
    _streamService.cancel();
    return super.close();
  }
}
