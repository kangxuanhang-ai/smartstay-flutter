import 'dart:async';
import 'dart:convert';

class SSEEvent {
  final String? type;
  final Map<String, dynamic>? data;
  SSEEvent(this.type, this.data);
}

class SSEParser {
  String _buffer = '';
  final StreamController<SSEEvent> _controller = StreamController<SSEEvent>.broadcast();

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
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'done') {
          _controller.add(SSEEvent('done', null));
          return;
        }
        _controller.add(SSEEvent(type, data));
      } catch (_) {
        // 不完整 JSON，等待更多数据（恢复原行到 buffer 开头）
        _buffer = line + '\n' + _buffer;
        break;
      }
    }
  }

  void close() {
    _controller.close();
  }
}
