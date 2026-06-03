import 'package:dio/dio.dart';
import 'audio_upload_stub.dart'
    if (dart.library.io) 'audio_upload_io.dart'
    if (dart.library.html) 'audio_upload_web.dart';

/// 读取音频字节并上传到 /api/ai/transcribe，返回识别文字
Future<String> uploadAndTranscribe({
  required String path,
  required Dio dio,
  String? accessToken,
}) async {
  final bytes = await readAudioBytes(path);

  final formData = FormData.fromMap({
    'audio': MultipartFile.fromBytes(bytes, filename: 'recording.m4a'),
  });

  final resp = await dio.post(
    '/api/ai/transcribe',
    data: formData,
    options: accessToken != null
        ? Options(headers: {'Authorization': 'Bearer $accessToken'})
        : null,
  );

  final text = resp.data['text'] as String?;
  if (text == null || text.isEmpty) {
    throw Exception('未识别到语音内容');
  }
  return text;
}
