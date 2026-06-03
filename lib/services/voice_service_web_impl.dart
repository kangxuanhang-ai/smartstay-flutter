import 'voice_service_base.dart';
import 'voice_service_web.dart';

class _VoiceServiceWebAdapter implements VoiceServiceBase {
  final _inner = VoiceServiceWeb();

  @override
  int get duration => _inner.duration;

  @override
  Future<void> startRecording() => _inner.startRecording();

  @override
  Future<List<int>?> stopRecording() async {
    // Web 平台不做字节转换，返回 null
    return null;
  }

  @override
  Future<String?> stopAndUploadDirect(String baseUrl, String? token) {
    return _inner.stopAndUpload(baseUrl, token);
  }

  @override
  Future<void> cancelRecording() => _inner.cancelRecording();

  @override
  void dispose() => _inner.dispose();
}

VoiceServiceBase createVoiceServiceImpl() => _VoiceServiceWebAdapter();
