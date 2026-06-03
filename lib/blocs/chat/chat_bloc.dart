import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import '../../core/sse_stream_handler.dart';
import '../../models/chat_card.dart';
import '../../services/chat_stream_service.dart';
import '../../services/voice_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<Object, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<ChatMessageSent>(_onSend);
    on<ChatStreamCancelled>(_onCancel);
    on<ChatSessionsLoadRequested>(_onLoadSessions);
    on<ChatSessionSwitchRequested>(_onSwitchSession);
    on<ChatNewSessionRequested>(_onNewSession);
    on<ChatVoiceRecordStarted>(_onVoiceStart);
    on<ChatVoiceRecordStopped>(_onVoiceStop);
    on<ChatClearTranscribedText>((event, emit) {
      emit(state.copyWith(clearTranscribedText: true));
    });
    on<ChatClearError>((event, emit) {
      emit(state.copyWith(error: null));
    });
  }

  final _api = ApiClient();
  final _streamService = ChatStreamService();
  final _voiceService = VoiceService();
  Timer? _recordingTimer;
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
    ));

    final cards = <ChatCard>[];
    var retried = false;
    final isFirstSend = _pendingNewSession;
    _pendingNewSession = false;

    await for (final streamEvent in _streamService.sendMessage(event.message, newSession: isFirstSend)) {
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
          ));
        }
      } else if (streamEvent is ChatStreamError) {
        if (streamEvent.message == 'auth_expired' && !retried) {
          retried = true;
          try {
            await _api.refreshAccessToken();
            // Retry with fresh token
            await for (final retryEvent in _streamService.sendMessage(event.message)) {
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
                  ));
                }
              } else if (retryEvent is ChatStreamError) {
                emit(state.copyWith(isStreaming: false, error: '登录已过期，请重新登录'));
                return;
              }
            }
          } catch (_) {
            emit(state.copyWith(isStreaming: false, error: '登录已过期，请重新登录'));
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
      ));
    } catch (_) {}
  }

  void _onNewSession(ChatNewSessionRequested event, Emitter<ChatState> emit) {
    _pendingNewSession = true;
    emit(ChatState(sessions: state.sessions));
  }

  void _startDurationTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final dur = state.recordingDuration + 1;
      if (dur >= 60) {
        add(const ChatVoiceRecordStopped());
      } else {
        emit(state.copyWith(recordingDuration: dur));
      }
    });
  }

  Future<void> _onVoiceStart(
    ChatVoiceRecordStarted event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _voiceService.startRecording();
      emit(state.copyWith(isRecording: true, recordingDuration: 0, error: null));
      _startDurationTimer();
    } catch (e) {
      final msg = e.toString().contains('权限') ? '请在设置中开启麦克风权限' : '录音失败，请重试';
      emit(state.copyWith(error: msg));
    }
  }

  Future<void> _onVoiceStop(
    ChatVoiceRecordStopped event,
    Emitter<ChatState> emit,
  ) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final path = await _voiceService.stopRecording();
      emit(state.copyWith(isRecording: false, isTranscribing: true));

      if (path == null || path.isEmpty) {
        emit(state.copyWith(isTranscribing: false, error: '录音失败，请重试'));
        return;
      }

      if (_voiceService.duration < 1) {
        emit(state.copyWith(isTranscribing: false, error: '录音时间太短'));
        return;
      }

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(path, filename: 'recording.m4a'),
      });

      final resp = await _api.post('/api/ai/transcribe', data: formData);
      final text = resp.data['text'] as String?;

      if (text == null || text.isEmpty) {
        emit(state.copyWith(isTranscribing: false, error: '未识别到语音内容'));
        return;
      }

      emit(state.copyWith(isTranscribing: false, transcribedText: text));
    } catch (e) {
      emit(state.copyWith(
        isTranscribing: false,
        error: e is DioException ? '识别失败，请重试' : '识别失败: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _recordingTimer?.cancel();
    _streamService.cancel();
    _voiceService.dispose();
    return super.close();
  }
}
