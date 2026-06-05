import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import '../../core/sse_parser.dart';
import '../../models/chat_card.dart';
import 'chat_event.dart';
import 'chat_state.dart';

import 'package:http/http.dart' as http;

class ChatBloc extends Bloc<Object, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<ChatMessageSent>(_onSend);
    on<ChatWebSearchToggled>(_onToggleWebSearch);
  }

  final _api = ApiClient();
  StreamSubscription? _httpSub;

  void _onToggleWebSearch(ChatWebSearchToggled event, Emitter<ChatState> emit) {
    emit(state.copyWith(webSearchEnabled: !state.webSearchEnabled));
  }

  Future<void> _onSend(ChatMessageSent event, Emitter<ChatState> emit) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true, text: event.message,
    );
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    final messages = [...state.messages, userMsg, ChatMessage(id: aiMsgId, isUser: false)];
    emit(ChatState(messages: messages, isStreaming: true, webSearchEnabled: state.webSearchEnabled));

    final cards = <ChatCard>[];

    try {
      if (kIsWeb) {
        // Web: 用 http 包拿完整 SSE 响应，同步解析后一次性 emit
        final bodyStr = await _fetchSSE('/api/ai/chat', event.message, state.webSearchEnabled);
        String aiText = '';
        for (final line in bodyStr.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            if (data['type'] == 'text' && data['content'] != null) {
              aiText += data['content'].toString();
            } else if (data['type'] == 'card' && data['card'] != null) {
              cards.add(ChatCard.fromJson(data['card'] as Map<String, dynamic>));
            }
          } catch (_) {}
        }
        final idx2 = state.messages.indexWhere((m) => m.id == aiMsgId);
        if (idx2 != -1) {
          final msgs2 = List<ChatMessage>.from(state.messages);
          msgs2[idx2] = ChatMessage(id: aiMsgId, isUser: false, text: aiText, cards: List.from(cards));
          emit(ChatState(messages: msgs2, isStreaming: false));
        } else {
          // 兜底：即使找不到原消息，也 emit 一条新消息
          final msgs2 = List<ChatMessage>.from(state.messages);
          msgs2.add(ChatMessage(id: aiMsgId, isUser: false, text: aiText, cards: List.from(cards)));
          emit(ChatState(messages: msgs2, isStreaming: false));
        }
      } else {
        // 移动端：ResponseType.stream 原生支持
        final resp = await _api.dio.post(
          '/api/ai/chat',
          data: {'message': event.message, 'web_search': state.webSearchEnabled},
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
            cards.add(ChatCard.fromJson(sseEvent.data!['card'] as Map<String, dynamic>));
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
      } // else (kIsWeb) block
    } catch (_) {
      emit(state.copyWith(isStreaming: false, error: '发送失败'));
    }
  }

  @override
  Future<void> close() {
    _httpSub?.cancel();
    return super.close();
  }

  /// Web 端用 http 包拿 SSE 响应，避免 Dio 兼容问题
  Future<String> _fetchSSE(String path, String message, bool webSearch) async {
    final baseUrl = _api.dio.options.baseUrl;
    final token = _api.accessToken ?? '';
    final resp = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message, 'web_search': webSearch}),
    );
    return resp.body;
  }
}
