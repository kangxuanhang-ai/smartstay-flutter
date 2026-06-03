import 'dart:io';
import 'package:dio/dio.dart';

Future<String> uploadAndTranscribe({
  required String path,
  required Dio dio,
  String? accessToken,
}) async {
  final file = File(path);
  final bytes = await file.readAsBytes();

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
