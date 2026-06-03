import 'dart:convert';
import 'dart:html' as html;
import 'package:dio/dio.dart';
import '../core/api_client.dart';

/// Web 平台：直接用 dart:html HttpRequest 上传 blob 音频
Future<String> uploadAndTranscribe({
  required String path,
  required Dio dio,
  String? accessToken,
}) async {
  final api = ApiClient();
  final token = accessToken ?? api.accessToken;
  final baseUrl = api.dio.options.baseUrl;

  // 从 blob URL 获取 blob 对象
  final blobRequest = await html.HttpRequest.request(
    path,
    responseType: 'blob',
  );
  final blob = blobRequest.response as html.Blob;

  // 构建 FormData
  final formData = html.FormData();
  formData.appendBlob('audio', blob, 'recording.m4a');

  // 用 HttpRequest 发送
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
