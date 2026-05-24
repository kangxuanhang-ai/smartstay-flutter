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
  StreamSubscription<SSEEvent>? _sseSub;

  Future<void> _onSend(ChatMessageSent event, Emitter<ChatState> emit) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: event.message,
    );

    final messages = [...state.messages, userMsg];
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = ChatMessage(id: aiMsgId, isUser: false);
    messages.add(aiMsg);

    emit(ChatState(messages: messages, isStreaming: true));

    try {
      final resp = await _api.dio.post(
        '/api/ai/chat',
        data: {'message': event.message},
        options: Options(responseType: ResponseType.stream),
      );

      final parser = SSEParser();
      final cards = <Map<String, dynamic>>[];

      _sseSub = parser.stream.listen((sseEvent) {
        final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
        if (idx == -1) return;

        final updatedMessages = List<ChatMessage>.from(state.messages);

        if (sseEvent.type == 'text' && sseEvent.data != null) {
          final currentText = updatedMessages[idx].text;
          updatedMessages[idx] = ChatMessage(
            id: aiMsgId,
            isUser: false,
            text: currentText + (sseEvent.data!['content'] ?? ''),
            cards: cards,
          );
        } else if (sseEvent.type == 'card' && sseEvent.data != null) {
          cards.add(sseEvent.data!['card'] as Map<String, dynamic>);
          updatedMessages[idx] = ChatMessage(
            id: aiMsgId,
            isUser: false,
            text: updatedMessages[idx].text,
            cards: List.from(cards),
          );
        } else if (sseEvent.type == 'done') {
          updatedMessages[idx] = ChatMessage(
            id: aiMsgId,
            isUser: false,
            text: updatedMessages[idx].text,
            cards: List.from(cards),
          );
          emit(ChatState(messages: updatedMessages, isStreaming: false));
          return;
        }

        emit(ChatState(messages: updatedMessages, isStreaming: true));
      });

      final stream = resp.data.stream as Stream<List<int>>;
      stream.transform(const Utf8Decoder()).listen(
        (chunk) => parser.addChunk(chunk),
        onError: (_) => emit(state.copyWith(isStreaming: false, error: '连接中断')),
        onDone: () => parser.close(),
      );
    } catch (_) {
      emit(state.copyWith(isStreaming: false, error: '发送失败'));
    }
  }

  @override
  Future<void> close() {
    _sseSub?.cancel();
    return super.close();
  }
}
