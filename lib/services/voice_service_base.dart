/// 录音服务接口
abstract class VoiceServiceBase {
  int get duration;
  Future<void> startRecording();
  Future<List<int>?> stopRecording();
  Future<void> cancelRecording();
  void dispose();
}
