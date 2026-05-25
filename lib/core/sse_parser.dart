import 'dart:async';
import 'dart:convert';

class SSEEvent {
  final String? type;
  final Map<String, dynamic>? data;
  SSEEvent(this.type, this.data);
}

class SSEParser {
  final StreamController<SSEEvent> _controller = StreamController<SSEEvent>.broadcast();
  String _buffer = '';
  int _failCount = 0;

  Stream<SSEEvent> get stream => _controller.stream;

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
        if (type == 'done') {
          _processRemainingLines();
          _controller.add(SSEEvent('done', null));
          return;
        }
        _controller.add(SSEEvent(type, data));
      } catch (_) {
        _failCount++;
        if (_failCount >= 10) {
          _failCount = 0;
          // 只丢弃当前行，保留剩余 buffer
          continue;
        } else {
          _buffer = line + '\n' + _buffer;
          break;
        }
      }
    }
  }

  void close() {
    _controller.close();
  }

  void _processRemainingLines() {
    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);

      if (line.isEmpty) continue;
      if (!line.startsWith('data: ')) continue;

      final jsonStr = line.substring(6);
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type != 'done') {
          _controller.add(SSEEvent(type, data));
        }
      } catch (_) {}
    }
  }
}
