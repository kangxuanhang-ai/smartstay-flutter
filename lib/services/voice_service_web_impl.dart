import 'voice_service_base.dart';
import 'voice_service_web.dart';

class _VoiceServiceWebAdapter implements VoiceServiceBase {
  final _inner = VoiceServiceWeb();

  @override
  int get duration => _inner.duration;

  @override
  Future<void> startRecording() => _inner.startRecording();

  @override
  Future<List<int>?> stopRecording() => _inner.stopRecording();

  @override
  Future<void> cancelRecording() => _inner.cancelRecording();

  @override
  void dispose() => _inner.dispose();
}

VoiceServiceBase createVoiceServiceImpl() => _VoiceServiceWebAdapter();
