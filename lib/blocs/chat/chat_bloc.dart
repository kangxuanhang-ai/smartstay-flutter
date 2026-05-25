import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import '../../core/sse_parser.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<Object, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<ChatMessageSent>(_onSend);
    on<ChatSSETextReceived>(_onText);
    on<ChatSSECardReceived>(_onCard);
    on<ChatSSECompleted>(_onDone);
  }

  final _api = ApiClient();
  StreamSubscription<SSEEvent>? _sseSub;
  String _aiMsgId = '';
  final List<Map<String, dynamic>> _cards = [];

  Future<void> _onSend(ChatMessageSent event, Emitter<ChatState> emit) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: event.message,
    );

    _aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    _cards.clear();
    final messages = [...state.messages, userMsg, ChatMessage(id: _aiMsgId, isUser: false)];
    emit(ChatState(messages: messages, isStreaming: true));

    try {
      final resp = await _api.dio.post(
        '/api/ai/chat',
        data: {'message': event.message},
        options: Options(responseType: ResponseType.stream),
      );

      final parser = SSEParser();
      _sseSub = parser.stream.listen((sseEvent) {
        if (sseEvent.type == 'text' && sseEvent.data != null) {
          add(ChatSSETextReceived(sseEvent.data!['content'] as String? ?? ''));
        } else if (sseEvent.type == 'card' && sseEvent.data != null) {
          add(ChatSSECardReceived(sseEvent.data!['card'] as Map<String, dynamic>));
        } else if (sseEvent.type == 'done') {
          add(ChatSSECompleted());
        }
      });

      final stream = resp.data.stream as Stream<List<int>>;
      stream.transform(const Utf8Decoder()).listen(
        (chunk) => parser.addChunk(chunk),
        onError: (_) => add(ChatSSECompleted()),
        onDone: () => parser.close(),
      );
    } catch (_) {
      emit(state.copyWith(isStreaming: false, error: '发送失败'));
    }
  }

  void _onText(ChatSSETextReceived event, Emitter<ChatState> emit) {
    final idx = state.messages.indexWhere((m) => m.id == _aiMsgId);
    if (idx == -1) return;
    final msgs = List<ChatMessage>.from(state.messages);
    msgs[idx] = ChatMessage(id: _aiMsgId, isUser: false, text: msgs[idx].text + event.text, cards: List.from(_cards));
    emit(ChatState(messages: msgs, isStreaming: true));
  }

  void _onCard(ChatSSECardReceived event, Emitter<ChatState> emit) {
    _cards.add(event.card);
    final idx = state.messages.indexWhere((m) => m.id == _aiMsgId);
    if (idx == -1) return;
    final msgs = List<ChatMessage>.from(state.messages);
    msgs[idx] = ChatMessage(id: _aiMsgId, isUser: false, text: msgs[idx].text, cards: List.from(_cards));
    emit(ChatState(messages: msgs, isStreaming: true));
  }

  void _onDone(ChatSSECompleted event, Emitter<ChatState> emit) {
    final idx = state.messages.indexWhere((m) => m.id == _aiMsgId);
    if (idx == -1) {
      emit(state.copyWith(isStreaming: false));
      return;
    }
    final msgs = List<ChatMessage>.from(state.messages);
    msgs[idx] = ChatMessage(id: _aiMsgId, isUser: false, text: msgs[idx].text, cards: List.from(_cards));
    emit(ChatState(messages: msgs, isStreaming: false));
  }

  @override
  Future<void> close() {
    _sseSub?.cancel();
    return super.close();
  }
}
