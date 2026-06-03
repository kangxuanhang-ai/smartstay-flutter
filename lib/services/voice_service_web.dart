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
    _recorder = html.MediaRecorder(stream, {'mimeType': 'audio/mp4'});

    _recorder!.addEventListener('dataavailable', (html.Event e) {
      final blobEvent = e as html.BlobEvent;
      if (blobEvent.data != null && blobEvent.data!.size > 0) {
        _chunks.add(blobEvent.data!);
      }
    });

    _stopCompleter = Completer<void>();
    _recorder!.addEventListener('stop', (_) {
      _recordedBlob = html.Blob(_chunks, 'audio/mp4');
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

  /// 直接上传 blob 到后端，返回识别文字
  /// 完全绕过字节转换
  Future<String?> stopAndUpload(String baseUrl, String? token) async {
    _durationTimer?.cancel();
    _durationTimer = null;
    if (_recorder == null) return null;
    if (_recorder!.state != 'recording') return null;

    _recorder!.stop();
    await _stopCompleter!.future;
    if (_recordedBlob == null) return null;

    // 直接用 FormData.appendBlob 上传，不做任何字节转换
    final formData = html.FormData();
    formData.appendBlob('audio', _recordedBlob!, 'recording.m4a');

    final response = await html.HttpRequest.request(
      '$baseUrl/api/ai/transcribe',
      method: 'POST',
      sendData: formData,
      requestHeaders: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final body = response.responseText ?? '{}';
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['text'] as String?;
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
