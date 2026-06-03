import 'dart:io';
import 'voice_service_base.dart';
import 'voice_service.dart';

class _VoiceServiceNative implements VoiceServiceBase {
  final _inner = VoiceService();

  @override
  int get duration => _inner.duration;

  @override
  Future<void> startRecording() => _inner.startRecording();

  @override
  Future<List<int>?> stopRecording() async {
    final path = await _inner.stopRecording();
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> cancelRecording() => _inner.cancelRecording();

  @override
  void dispose() => _inner.dispose();
}

VoiceServiceBase createVoiceServiceImpl() => _VoiceServiceNative();
