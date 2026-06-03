import 'dart:html' as html;
import 'dart:typed_data';

Future<List<int>> readAudioBytes(String path) async {
  final request = await html.HttpRequest.request(
    path,
    responseType: 'arraybuffer',
  );
  final buffer = request.response as ByteBuffer;
  return Uint8List.view(buffer);
}
