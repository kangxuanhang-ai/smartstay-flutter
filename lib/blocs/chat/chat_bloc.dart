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
  }

  final _api = ApiClient();
  StreamSubscription? _httpSub;

  Future<void> _onSend(ChatMessageSent event, Emitter<ChatState> emit) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true, text: event.message,
    );
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    final messages = [...state.messages, userMsg, ChatMessage(id: aiMsgId, isUser: false)];
    emit(ChatState(messages: messages, isStreaming: true));

    final cards = <Map<String, dynamic>>[];

    try {
      final resp = await _api.dio.post(
        '/api/ai/chat',
        data: {'message': event.message},
        options: Options(responseType: ResponseType.stream),
      );

      final parser = SSEParser();
      final stream = resp.data.stream as Stream<List<int>>;

      var streamError = false;
      final httpSub = stream.transform(const Utf8Decoder()).listen(
        (chunk) => parser.addChunk(chunk),
        onError: (_) {
          streamError = true;
          parser.close();
        },
        onDone: () => parser.close(),
      );
      _httpSub = httpSub;

      await emit.forEach<SSEEvent>(
        parser.stream,
        onData: (sseEvent) {
          final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
          if (idx == -1) return state;

          final msgs = List<ChatMessage>.from(state.messages);

          if (sseEvent.type == 'text' && sseEvent.data != null) {
            msgs[idx] = ChatMessage(
              id: aiMsgId, isUser: false,
              text: msgs[idx].text + (sseEvent.data!['content'] ?? '').toString(),
              cards: List.from(cards),
            );
            return ChatState(messages: msgs, isStreaming: true);
          }

          if (sseEvent.type == 'card' && sseEvent.data != null) {
            cards.add(sseEvent.data!['card'] as Map<String, dynamic>);
            msgs[idx] = ChatMessage(
              id: aiMsgId, isUser: false, text: msgs[idx].text, cards: List.from(cards),
            );
            return ChatState(messages: msgs, isStreaming: true);
          }

          if (sseEvent.type == 'done') {
            msgs[idx] = ChatMessage(
              id: aiMsgId, isUser: false, text: msgs[idx].text, cards: List.from(cards),
            );
            return ChatState(messages: msgs, isStreaming: false);
          }

          return state;
        },
      );
      // 无论流如何结束，重置 streaming
      if (state.isStreaming) {
        emit(state.copyWith(isStreaming: false));
      }
      if (streamError) {
        emit(state.copyWith(isStreaming: false, error: '连接中断'));
      }
    } catch (_) {
      emit(state.copyWith(isStreaming: false, error: '发送失败'));
    }
  }

  @override
  Future<void> close() {
    _httpSub?.cancel();
    return super.close();
  }
}
