import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config.dart';
import 'api_client.dart';

class WsService {
  static final WsService _instance = WsService._internal();
  factory WsService() => _instance;

  WsService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _connected = false;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect() {
    if (_connected) return;
    final token = ApiClient().accessToken;
    if (token == null) return;

    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _connected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String);
            if (msg is Map<String, dynamic>) {
              _eventController.add(msg);
            }
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          _scheduleReconnect();
        },
        onError: (_) {
          _connected = false;
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  bool get isConnected => _connected;
}
