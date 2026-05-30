/// Stub for dart:html on non-web platforms.
/// Only the subset of HttpRequest used by ChatBloc is stubbed.

class HttpRequest {
  String? responseText;
  int status = 0;
  String responseType = '';

  void open(String method, String url) {}
  void setRequestHeader(String name, String value) {}
  void send([Object? data]) {}
  void abort() {}

  Stream<ProgressEvent> get onProgress => const Stream.empty();
  Stream<ProgressEvent> get onLoad => const Stream.empty();
  Stream<ProgressEvent> get onError => const Stream.empty();
}

class ProgressEvent {}
