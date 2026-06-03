/// 录音服务接口 + 非 web 平台 stub

abstract class VoiceServiceBase {
  int get duration;
  Future<void> startRecording();
  Future<List<int>?> stopRecording();
  Future<void> cancelRecording();
  void dispose();
}

VoiceServiceBase createVoiceServiceImpl() {
  throw UnsupportedError('Use dart:io or dart:html platform');
}
