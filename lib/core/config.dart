class AppConfig {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String wsUrl = 'ws://10.0.2.2:8000/ws';

  static String get apiUrl => '$baseUrl/api';
}
