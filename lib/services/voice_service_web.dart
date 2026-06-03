import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// Web 平台录音服务：直接使用浏览器 MediaRecorder API
class VoiceServiceWeb {
  html.MediaRecorder? _recorder;
  html.Blob? _recordedBlob;
  final List<html.Blob> _chunks = [];
  Timer? _durationTimer;
  int _duration = 0;
  Completer<void>? _stopCompleter;

  int get duration => _duration;

  Future<void> startRecording() async {
    _chunks.clear();
    _recordedBlob = null;
    _duration = 0;

    final stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
    _recorder = html.MediaRecorder(stream, {'mimeType': 'audio/webm'});

    _recorder!.addEventListener('dataavailable', (html.Event e) {
      final blobEvent = e as html.BlobEvent;
      if (blobEvent.data != null && blobEvent.data!.size > 0) {
        _chunks.add(blobEvent.data!);
      }
    });

    _stopCompleter = Completer<void>();
    _recorder!.addEventListener('stop', (_) {
      _recordedBlob = html.Blob(_chunks, 'audio/webm');
      stream.getTracks().forEach((t) => t.stop());
      if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
        _stopCompleter!.complete();
      }
    });

    _recorder!.start();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _duration++;
    });
  }

  Future<List<int>?> stopRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    if (_recorder == null) return null;

    _recorder!.stop();
    await _stopCompleter!.future;
    if (_recordedBlob == null) return null;
    return _readBlobAsBase64(_recordedBlob!);
  }

  Future<List<int>> _readBlobAsBase64(html.Blob blob) async {
    final reader = html.FileReader();
    final c = Completer<List<int>>();

    reader.onLoad.listen((_) {
      try {
        final dataUrl = reader.result as String;
        final base64Part = dataUrl.split(',').last;
        final bytes = base64Decode(base64Part);
        c.complete(bytes);
      } catch (e) {
        c.completeError('解码音频失败: $e');
      }
    });

    reader.onError.listen((e) {
      c.completeError('读取音频失败: $e');
    });

    reader.readAsDataUrl(blob);
    return c.future;
  }

  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    if (_recorder != null && _recorder!.state == 'recording') {
      _recorder!.stop();
    }
    _recorder = null;
    _chunks.clear();
  }

  void dispose() {
    _durationTimer?.cancel();
    if (_recorder != null && _recorder!.state == 'recording') {
      _recorder!.stop();
    }
    _recorder = null;
  }
}
