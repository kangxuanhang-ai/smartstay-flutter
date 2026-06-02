import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../core/api_client.dart';
import '../../core/sse_parser.dart';
import 'chat_event.dart';
import 'chat_state.dart';

// Web platform: use dart:html for SSE streaming; stub on non-web
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html;

/// Token 过期异常，触发 _onSend 中的刷新重试逻辑
class _AuthExpiredException implements Exception {}

class ChatBloc extends Bloc<Object, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<ChatMessageSent>(_onSend);
    on<ChatStreamCancelled>(_onCancel);
  }

  final _api = ApiClient();
  StreamSubscription? _httpSub;
  html.HttpRequest? _webRequest;

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
      if (kIsWeb) {
        try {
          await _sendViaWeb(event.message, aiMsgId, cards, emit);
        } on _AuthExpiredException {
          try {
            await _api.refreshAccessToken();
          } catch (_) {
            emit(state.copyWith(isStreaming: false, error: '登录已过期，请重新登录'));
            return;
          }
          await _sendViaWeb(event.message, aiMsgId, cards, emit);
        }
      } else {
        try {
          await _sendViaDio(event.message, aiMsgId, cards, emit);
        } on _AuthExpiredException {
          try {
            await _api.refreshAccessToken();
          } catch (_) {
            emit(state.copyWith(isStreaming: false, error: '登录已过期，请重新登录'));
            return;
          }
          await _sendViaDio(event.message, aiMsgId, cards, emit);
        }
      }
    } catch (_) {
      emit(state.copyWith(isStreaming: false, error: '发送失败'));
    }
  }

  /// Web 平台：使用 dart:html HttpRequest 实现 SSE 流式接收
  Future<void> _sendViaWeb(
    String message,
    String aiMsgId,
    List<Map<String, dynamic>> cards,
    Emitter<ChatState> emit,
  ) async {
    final completer = Completer<void>();
    final token = _api.accessToken;

    final request = html.HttpRequest();
    _webRequest = request;

    request.open('POST', '${_api.dio.options.baseUrl}/api/ai/chat');
    request.setRequestHeader('Content-Type', 'application/json');
    if (token != null) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.responseType = 'text'; // SSE 需要文本模式

    int lastPos = 0;

    request.onProgress.listen((_) {
      final fullText = request.responseText ?? '';
      if (fullText.length > lastPos) {
        final chunk = fullText.substring(lastPos);
        lastPos = fullText.length;

        // 按行解析 SSE 数据
        final lines = chunk.split('\n');
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty || !line.startsWith('data: ')) continue;

          final jsonStr = line.substring(6);
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final type = data['type'] as String?;

            if (type == 'text') {
              final content = (data['content'] ?? '').toString();
              final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
              if (idx == -1) continue;
              final msgs = List<ChatMessage>.from(state.messages);
              msgs[idx] = ChatMessage(
                id: aiMsgId, isUser: false,
                text: msgs[idx].text + content,
                cards: List.from(cards),
              );
              emit(ChatState(messages: msgs, isStreaming: true));
            } else if (type == 'card') {
              cards.add(data['card'] as Map<String, dynamic>);
              final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
              if (idx == -1) continue;
              final msgs = List<ChatMessage>.from(state.messages);
              msgs[idx] = ChatMessage(
                id: aiMsgId, isUser: false,
                text: msgs[idx].text, cards: List.from(cards),
              );
              emit(ChatState(messages: msgs, isStreaming: true));
            } else if (type == 'done') {
              final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
              if (idx == -1) continue;
              final msgs = List<ChatMessage>.from(state.messages);
              msgs[idx] = ChatMessage(
                id: aiMsgId, isUser: false,
                text: msgs[idx].text, cards: List.from(cards),
              );
              emit(ChatState(messages: msgs, isStreaming: false));
              if (!completer.isCompleted) completer.complete();
            }
          } catch (_) {}
        }
      }
    });

    request.onLoad.listen((_) {
      if (!completer.isCompleted) {
        // 检测 401 Unauthorized — token 过期
        if (request.status == 401) {
          completer.completeError(_AuthExpiredException());
          return;
        }
        // onload 可能在 onProgress 之前触发（小响应），也确保解析
        final fullText = request.responseText ?? '';
        if (fullText.length > lastPos) {
          final chunk = fullText.substring(lastPos);
          // 复用同一套解析逻辑
          final lines = chunk.split('\n');
          for (final rawLine in lines) {
            final line = rawLine.trim();
            if (line.isEmpty || !line.startsWith('data: ')) continue;
            final jsonStr = line.substring(6);
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final type = data['type'] as String?;
              if (type == 'text') {
                final content = (data['content'] ?? '').toString();
                final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
                if (idx != -1) {
                  final msgs = List<ChatMessage>.from(state.messages);
                  msgs[idx] = ChatMessage(
                    id: aiMsgId, isUser: false,
                    text: msgs[idx].text + content, cards: List.from(cards),
                  );
                  emit(ChatState(messages: msgs, isStreaming: true));
                }
              } else if (type == 'card') {
                cards.add(data['card'] as Map<String, dynamic>);
              }
            } catch (_) {}
          }
        }
        final idx = state.messages.indexWhere((m) => m.id == aiMsgId);
        if (idx != -1) {
          final msgs = List<ChatMessage>.from(state.messages);
          msgs[idx] = ChatMessage(
            id: aiMsgId, isUser: false,
            text: msgs[idx].text, cards: List.from(cards),
          );
          emit(ChatState(messages: msgs, isStreaming: false));
        }
        completer.complete();
      }
    });

    request.onError.listen((_) {
      if (!completer.isCompleted) {
        emit(state.copyWith(isStreaming: false, error: '连接中断'));
        completer.completeError(Exception('HTTP request error'));
      }
    });

    request.send(jsonEncode({'message': message}));

    await completer.future;
    if (state.isStreaming) {
      emit(state.copyWith(isStreaming: false));
    }
  }

  /// 非 Web 平台：使用 http 包处理 SSE 流
  Future<void> _sendViaDio(
    String message,
    String aiMsgId,
    List<Map<String, dynamic>> cards,
    Emitter<ChatState> emit,
  ) async {
    final uri = Uri.parse('${_api.dio.options.baseUrl}/api/ai/chat');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.body = jsonEncode({'message': message});

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode == 401) {
      throw _AuthExpiredException();
    }

    final parser = SSEParser();
    final stream = streamedResponse.stream;

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
    if (state.isStreaming) {
      emit(state.copyWith(isStreaming: false));
    }
    if (streamError) {
      emit(state.copyWith(isStreaming: false, error: '连接中断'));
    }
  }

  void _onCancel(ChatStreamCancelled event, Emitter<ChatState> emit) {
    _httpSub?.cancel();
    _httpSub = null;
    _webRequest?.abort();
    _webRequest = null;
    emit(state.copyWith(isStreaming: false));
  }

  @override
  Future<void> close() {
    _httpSub?.cancel();
    _webRequest?.abort();
    return super.close();
  }
}
