import 'dart:async';
import 'dart:convert';

import '../models/chat_card.dart';

sealed class ChatStreamEvent {}

class ChatStreamText extends ChatStreamEvent {
  final String content;
  ChatStreamText(this.content);
}

class ChatStreamCard extends ChatStreamEvent {
  final ChatCard card;
  ChatStreamCard(this.card);
}

class ChatStreamDone extends ChatStreamEvent {}

class ChatStreamError extends ChatStreamEvent {
  final String message;
  ChatStreamError(this.message);
}

class SSEStreamHandler {
  final _controller = StreamController<ChatStreamEvent>.broadcast();
  String _buffer = '';
  int _failCount = 0;

  Stream<ChatStreamEvent> get stream => _controller.stream;

  void addChunk(String chunk) {
    _buffer += chunk;

    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);

      if (line.isEmpty) continue;
      if (!line.startsWith('data: ')) continue;

      final jsonStr = line.substring(6);
      try {
        _failCount = 0;
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final type = data['type'] as String?;

        if (type == 'text') {
          final content = (data['content'] ?? '').toString();
          _controller.add(ChatStreamText(content));
        } else if (type == 'card') {
          final cardData = data['card'] as Map<String, dynamic>;
          _controller.add(ChatStreamCard(ChatCard.fromJson(cardData)));
        } else if (type == 'done') {
          _controller.add(ChatStreamDone());
          return;
        }
      } catch (_) {
        _failCount++;
        if (_failCount >= 10) {
          _failCount = 0;
          continue;
        } else {
          _buffer = '$line\n$_buffer';
          break;
        }
      }
    }
  }

  void addError(String message) {
    _controller.add(ChatStreamError(message));
  }

  void close() {
    _controller.close();
  }
}
