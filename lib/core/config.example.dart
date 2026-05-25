class AppConfig {
  // 复制此文件为 config.dart，填写你的后端 IP
  // Android 模拟器用 10.0.2.2，真机用电脑局域网 IP
  static const String baseUrl = 'http://YOUR_IP:8000';
  static const String wsUrl = 'ws://YOUR_IP:8000/ws';

  static String get apiUrl => '$baseUrl/api';
}
