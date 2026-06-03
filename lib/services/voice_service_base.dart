/// 录音服务接口
abstract class VoiceServiceBase {
  int get duration;
  Future<void> startRecording();

  /// 停止录音并返回音频字节。Web 平台返回 null（使用 stopAndUploadDirect 代替）
  Future<List<int>?> stopRecording();

  /// 停止录音并直接上传到后端，返回识别文字。仅 Web 平台使用。
  Future<String?> stopAndUploadDirect(String baseUrl, String? token) async {
    return null;
  }

  Future<void> cancelRecording();
  void dispose();
}
