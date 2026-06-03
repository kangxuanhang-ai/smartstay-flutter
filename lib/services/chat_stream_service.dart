import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../core/sse_stream_handler.dart';

import '../blocs/chat/html_stub.dart' if (dart.library.html) 'dart:html' as html;

class ChatStreamService {
  final _api = ApiClient();
  http.Client? _httpClient;
  html.HttpRequest? _webRequest;

  Stream<ChatStreamEvent> sendMessage(String message, {bool newSession = false}) async* {
    final handler = SSEStreamHandler();

    if (kIsWeb) {
      yield* _sendViaWeb(message, handler, newSession: newSession);
    } else {
      yield* _sendViaNative(message, handler, newSession: newSession);
    }
  }

  Stream<ChatStreamEvent> _sendViaNative(String message, SSEStreamHandler handler, {bool newSession = false}) async* {
    final uri = Uri.parse('${_api.dio.options.baseUrl}/api/ai/chat');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    final token = _api.accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.body = jsonEncode({'message': message, 'new_session': newSession});

    final client = http.Client();
    _httpClient = client;

    try {
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 401) {
        handler.addError('auth_expired');
        yield* handler.stream;
        return;
      }

      final sub = streamedResponse.stream
          .transform(const Utf8Decoder())
          .listen(
            handler.addChunk,
            onError: (_) => handler.addError('连接中断'),
            onDone: () => handler.close(),
          );

      yield* handler.stream;
      await sub.asFuture<void>().catchError((_) {});
    } catch (_) {
      handler.addError('发送失败');
      yield* handler.stream;
    } finally {
      client.close();
      _httpClient = null;
    }
  }

  Stream<ChatStreamEvent> _sendViaWeb(String message, SSEStreamHandler handler, {bool newSession = false}) async* {
    final completer = Completer<void>();
    final token = _api.accessToken;

    final request = html.HttpRequest();
    _webRequest = request;

    request.open('POST', '${_api.dio.options.baseUrl}/api/ai/chat');
    request.setRequestHeader('Content-Type', 'application/json');
    if (token != null) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.responseType = 'text';

    int lastPos = 0;

    request.onProgress.listen((_) {
      final fullText = request.responseText ?? '';
      if (fullText.length > lastPos) {
        handler.addChunk(fullText.substring(lastPos));
        lastPos = fullText.length;
      }
    });

    request.onLoad.listen((_) {
      if (!completer.isCompleted) {
        if (request.status == 401) {
          handler.addError('auth_expired');
          completer.complete();
          return;
        }
        final fullText = request.responseText ?? '';
        if (fullText.length > lastPos) {
          handler.addChunk(fullText.substring(lastPos));
        }
        handler.close();
        completer.complete();
      }
    });

    request.onError.listen((_) {
      if (!completer.isCompleted) {
        handler.addError('连接中断');
        completer.complete();
      }
    });

    request.send(jsonEncode({'message': message, 'new_session': newSession}));

    yield* handler.stream;
    await completer.future;
    _webRequest = null;
  }

  void cancel() {
    _httpClient?.close();
    _httpClient = null;
    _webRequest?.abort();
    _webRequest = null;
  }
}
