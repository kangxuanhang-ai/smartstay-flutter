import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// Web 平台录音服务：直接使用浏览器 MediaRecorder API
/// 绕过 record 包的 NativeArrayBuffer 类型问题
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

    // 用 readAsDataUrl 获取 base64，再解码为字节
    // 避免 readAsArrayBuffer 的 NativeArrayBuffer 类型问题
    final reader = html.FileReader();
    final completer = Completer<List<int>>();

    reader.onLoad.listen((_) {
      final dataUrl = reader.result as String;
      // data:audio/webm;base64,AAAA...
      final base64Str = dataUrl.split(',').last;
      final bytes = base64Decode(base64Str);
      completer.complete(bytes);
    });

    reader.onError.listen((e) {
      completer.completeError(e ?? '读取音频失败');
    });

    reader.readAsDataUrl(_recordedBlob!);
    return completer.future;
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
