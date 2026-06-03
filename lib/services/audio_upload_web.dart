import 'dart:html' as html;
import 'dart:typed_data';

Future<List<int>> readAudioBytes(String path) async {
  final request = await html.HttpRequest.request(
    path,
    responseType: 'arraybuffer',
  );
  final data = request.response as TypedData;
  return data.buffer.asUint8List();
}
