import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import '../../core/sse_stream_handler.dart';
import '../../core/voice_service.dart';
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
    on<ChatVoiceRecordingStarted>(_onVoiceStart);
    on<ChatVoiceDurationUpdated>(_onVoiceDurationUpdate);
    on<ChatVoiceRecordingStopped>(_onVoiceStop);
    on<ChatVoiceRecordingCancelled>(_onVoiceCancel);
    on<ChatVoiceTranscribeRequested>(_onVoiceTranscribe);
  }

  final _api = ApiClient();
  final _streamService = ChatStreamService();
  final _voiceService = VoiceService.instance;
  bool _pendingNewSession = false;
  StreamSubscription<int>? _voiceDurationSub;

  // ── Error Classification ──
  ChatError _classifyError(Object error, [int? statusCode]) {
    if (error is SocketException || error is HttpException) {
      return const ChatError(
        type: 'network', title: '网络不可用',
        message: '请检查网络连接后重试', actionLabel: '重新连接',
      );
    }
    if (statusCode == 401) {
      return const ChatError(
        type: 'auth', title: '登录已过期',
        message: '请重新登录以继续使用', actionLabel: '重新登录',
      );
    }
    if (statusCode == 403) {
      return const ChatError(
        type: 'forbidden', title: '请先办理入住',
        message: '入住后即可使用 AI 管家服务', actionLabel: '前往前台',
      );
    }
    if (statusCode == 500 || statusCode == 502 || statusCode == 503 ||
        error is TimeoutException) {
      return const ChatError(
        type: 'server', title: 'AI 暂时不可用',
        message: '服务繁忙，请稍后再试', actionLabel: '重试',
        secondaryLabel: '联系前台',
      );
    }
    return ChatError(
      type: 'server', title: '发生错误',
      message: error.toString(), actionLabel: '重试',
    );
  }

  int? _extractStatusCode(Object error) {
    final str = error.toString();
    // Match HTTP status code patterns like "401", "statusCode: 403"
    final match = RegExp(r'(?:status|code)[:\s]*(\d{3})').firstMatch(str);
    if (match != null) return int.tryParse(match.group(1)!);
    // Match standalone status codes at word boundaries
    if (RegExp(r'\b401\b').hasMatch(str)) return 401;
    if (RegExp(r'\b403\b').hasMatch(str)) return 403;
    if (RegExp(r'\b500\b').hasMatch(str)) return 500;
    if (RegExp(r'\b502\b').hasMatch(str)) return 502;
    if (RegExp(r'\b503\b').hasMatch(str)) return 503;
    return null;
  }

  // ── Voice Handlers ──
  void _onVoiceStart(ChatVoiceRecordingStarted event, Emitter<ChatState> emit) {
    emit(state.copyWith(isRecording: true, recordingDuration: 0));
    _voiceDurationSub?.cancel();
    _voiceDurationSub = _voiceService.durationStream.listen((duration) {
      if (!isClosed) {
        add(ChatVoiceDurationUpdated(duration));
      }
    });
  }

  void _onVoiceDurationUpdate(ChatVoiceDurationUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(recordingDuration: event.duration));
  }

  void _onVoiceStop(ChatVoiceRecordingStopped event, Emitter<ChatState> emit) {
    _voiceDurationSub?.cancel();
    emit(state.copyWith(isRecording: false, isTranscribing: true));
  }

  void _onVoiceCancel(ChatVoiceRecordingCancelled event, Emitter<ChatState> emit) {
    _voiceDurationSub?.cancel();
    emit(state.copyWith(isRecording: false, isTranscribing: false, recordingDuration: 0));
  }

  Future<void> _onVoiceTranscribe(ChatVoiceTranscribeRequested event, Emitter<ChatState> emit) async {
    try {
      final text = await _voiceService.transcribe(event.audioPath);
      emit(state.copyWith(isTranscribing: false));
      if (text != null && text.isNotEmpty) {
        add(ChatMessageSent(text, webSearch: state.webSearchEnabled));
      }
    } catch (_) {
      emit(state.copyWith(isTranscribing: false));
    }
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
    emit(state.copyWith(messages: messages, isStreaming: true, clearChatError: true));

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
            id: aiMsgId, isUser: false,
            text: msgs[idx].text + streamEvent.content,
            cards: List<ChatCard>.from(cards), isThinking: false,
          );
          emit(state.copyWith(messages: msgs, isStreaming: true));
        } else if (streamEvent is ChatStreamCard) {
          cards.add(streamEvent.card);
          final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
          if (idx == -1) continue;
          final msgs = List<ChatMessage>.from(state.messages);
          msgs[idx] = ChatMessage(
            id: aiMsgId, isUser: false,
            text: msgs[idx].text,
            cards: List<ChatCard>.from(cards), isThinking: false,
          );
          emit(state.copyWith(messages: msgs, isStreaming: true));
        } else if (streamEvent is ChatStreamDone) {
          final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1) {
            final msgs = List<ChatMessage>.from(state.messages);
            msgs[idx] = ChatMessage(
              id: aiMsgId, isUser: false,
              text: msgs[idx].text, cards: List<ChatCard>.from(cards),
            );
            emit(state.copyWith(messages: msgs, isStreaming: false));
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
                    cards: List<ChatCard>.from(cards), isThinking: false,
                  );
                  emit(state.copyWith(messages: msgs, isStreaming: true));
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
                    emit(state.copyWith(messages: msgs, isStreaming: false));
                  }
                } else if (retryEvent is ChatStreamError) {
                  final msgs = List<ChatMessage>.from(state.messages)
                    ..removeWhere((m) => m.id == aiMsgId);
                  emit(state.copyWith(
                    messages: msgs, isStreaming: false,
                    chatError: const ChatError(type: 'auth', title: '登录已过期', message: '请重新登录以继续使用', actionLabel: '重新登录'),
                  ));
                  return;
                }
              }
            } catch (_) {
              final msgs = List<ChatMessage>.from(state.messages)
                ..removeWhere((m) => m.id == aiMsgId);
              emit(state.copyWith(
                messages: msgs, isStreaming: false,
                chatError: const ChatError(type: 'auth', title: '登录已过期', message: '请重新登录以继续使用', actionLabel: '重新登录'),
              ));
              return;
            }
          } else {
            final msgs = List<ChatMessage>.from(state.messages)
              ..removeWhere((m) => m.id == aiMsgId);
            final statusCode = _extractStatusCode(streamEvent.message);
            emit(state.copyWith(
              messages: msgs, isStreaming: false,
              chatError: _classifyError(Exception(streamEvent.message), statusCode),
            ));
            return;
          }
        }
      }
    } catch (e) {
      final msgs = List<ChatMessage>.from(state.messages)
        ..removeWhere((m) => m.id == aiMsgId);
      emit(state.copyWith(
        messages: msgs, isStreaming: false,
        chatError: _classifyError(e, _extractStatusCode(e)),
      ));
      return;
    }

    if (state.isStreaming) {
      emit(state.copyWith(isStreaming: false));
    }
  }

  void _onCancel(ChatStreamCancelled event, Emitter<ChatState> emit) {
    _streamService.cancel();
    emit(state.copyWith(isStreaming: false));
  }

  Future<void> _onLoadSessions(ChatSessionsLoadRequested event, Emitter<ChatState> emit) async {
    try {
      final resp = await _api.get('/api/ai/chat/sessions');
      final sessions = (resp.data as List).cast<Map<String, dynamic>>();
      emit(state.copyWith(sessions: sessions));
    } catch (_) {
      emit(state.copyWith(chatError: const ChatError(
        type: 'network', title: '加载失败', message: '无法加载聊天记录', actionLabel: '重试',
      )));
    }
  }

  Future<void> _onSwitchSession(ChatSessionSwitchRequested event, Emitter<ChatState> emit) async {
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
    } catch (_) {
      emit(state.copyWith(chatError: const ChatError(
        type: 'network', title: '加载失败', message: '无法加载会话历史', actionLabel: '重试',
      )));
    }
  }

  void _onNewSession(ChatNewSessionRequested event, Emitter<ChatState> emit) {
    _pendingNewSession = true;
    emit(state.copyWith(
      messages: [],
      clearChatError: true,
      isRecording: false,
      isTranscribing: false,
      recordingDuration: 0,
    ));
  }

  void _onToggleWebSearch(ChatWebSearchToggled event, Emitter<ChatState> emit) {
    emit(state.copyWith(webSearchEnabled: !state.webSearchEnabled));
  }

  void _onRegenerate(ChatRegenerate event, Emitter<ChatState> emit) {
    if (state.isStreaming) return;
    if (state.messages.isEmpty) return;

    final lastAiIdx = state.messages.lastIndexWhere((m) => !m.isUser);
    if (lastAiIdx == -1) return;

    final userMsgIdx = state.messages.lastIndexWhere((m) => m.isUser, lastAiIdx);
    if (userMsgIdx == -1) return;

    final userText = state.messages[userMsgIdx].text;
    final msgs = List<ChatMessage>.from(state.messages)..removeAt(lastAiIdx);

    emit(state.copyWith(messages: msgs, clearChatError: true));
    add(ChatMessageSent(userText, webSearch: state.webSearchEnabled));
  }

  void _onDismissError(ChatErrorDismissed event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearChatError: true));
  }

  @override
  Future<void> close() {
    _voiceDurationSub?.cancel();
    _streamService.cancel();
    return super.close();
  }
}
