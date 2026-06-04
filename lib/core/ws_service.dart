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
  int _retryCount = 0;
  static const _maxRetries = 5;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect() {
    if (_connected) return;
    if (_retryCount >= _maxRetries) return; // 停止重试
    final token = ApiClient().accessToken;
    if (token == null) return;

    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _connected = true;
      _retryCount = 0; // 连接成功，重置计数

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
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    // 退避: 3s, 6s, 12s, 24s, 30s (cap)
    final delay = Duration(seconds: (3 * _retryCount).clamp(3, 30));
    _reconnectTimer = Timer(delay, () => connect());
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _retryCount = 0;
  }

  bool get isConnected => _connected;
}
