import 'package:dio/dio.dart';

Future<String> uploadAndTranscribe({
  required List<int> bytes,
  required Dio dio,
  String? accessToken,
}) async {
  final formData = FormData.fromMap({
    'audio': MultipartFile.fromBytes(bytes, filename: 'recording.webm'),
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
