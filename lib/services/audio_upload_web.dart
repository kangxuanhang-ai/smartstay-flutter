import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

/// Web 平台：用 dart:html HttpRequest 上传音频字节
Future<String> uploadAndTranscribe({
  required List<int> bytes,
  required Dio dio,
  String? accessToken,
}) async {
  final api = ApiClient();
  final token = accessToken ?? api.accessToken;
  final baseUrl = api.dio.options.baseUrl;

  // 构建 FormData
  final blob = html.Blob([Uint8List.fromList(bytes)], 'audio/webm');
  final formData = html.FormData();
  formData.appendBlob('audio', blob, 'recording.webm');

  // 用 HttpRequest 发送（绕过 Dio 的 MultipartFile web 兼容问题）
  final response = await html.HttpRequest.request(
    '$baseUrl/api/ai/transcribe',
    method: 'POST',
    sendData: formData,
    requestHeaders: {
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  final body = response.responseText ?? '{}';
  final data = jsonDecode(body) as Map<String, dynamic>;
  final text = data['text'] as String?;
  if (text == null || text.isEmpty) {
    throw Exception('未识别到语音内容');
  }
  return text;
}
