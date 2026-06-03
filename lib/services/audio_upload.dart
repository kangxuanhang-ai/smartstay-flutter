import 'package:dio/dio.dart';
import 'audio_upload_stub.dart'
    if (dart.library.io) 'audio_upload_io.dart'
    if (dart.library.html) 'audio_upload_web.dart' as impl;

/// 上传音频字节到 /api/ai/transcribe，返回识别文字
Future<String> uploadAndTranscribe({
  required List<int> bytes,
  required Dio dio,
  String? accessToken,
}) {
  return impl.uploadAndTranscribe(bytes: bytes, dio: dio, accessToken: accessToken);
}
