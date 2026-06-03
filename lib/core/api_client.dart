import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _failedQueue = [];

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  ApiClient._internal() : _storage = FlutterSecureStorage() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(minutes: 5),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_TokenInterceptor());
    dio.interceptors.add(InterceptorsWrapper(onError: _onError));
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401 && _refreshToken != null) {
      final req = error.requestOptions;
      // Prevent infinite loop: if this request was already retried, stop
      if (req.extra['_retried'] == true) {
        await clearTokens();
        return handler.next(error);
      }
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          await refreshAccessToken();
          final token = _accessToken;
          req.headers['Authorization'] = 'Bearer $token';
          req.extra['_retried'] = true;
          for (final entry in _failedQueue) {
            entry.options.headers['Authorization'] = 'Bearer $token';
            entry.options.extra['_retried'] = true;
            entry.handler.resolve(await dio.fetch(entry.options));
          }
          _failedQueue.clear();
          final resp = await dio.fetch(req);
          return handler.resolve(resp);
        } catch (_) {
          for (final entry in _failedQueue) {
            entry.handler.next(DioException(requestOptions: entry.options));
          }
          _failedQueue.clear();
          _isRefreshing = false;
          await clearTokens();
          return handler.next(error);
        }
      } else {
        _failedQueue.add((options: req, handler: handler));
        return;
      }
    }
    return handler.next(error);
  }

  void setTokens(String access, String refresh) {
    _accessToken = access;
    _refreshToken = refresh;
    if (kIsWeb) {
      _memoryFallback[_accessKey] = access;
      _memoryFallback[_refreshKey] = refresh;
    } else {
      _storage.write(key: _accessKey, value: access);
      _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    if (kIsWeb) {
      _memoryFallback.remove(_accessKey);
      _memoryFallback.remove(_refreshKey);
    } else {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    }
  }

  Future<bool> restoreTokens() async {
    if (kIsWeb) {
      _accessToken = _memoryFallback[_accessKey];
      _refreshToken = _memoryFallback[_refreshKey];
    } else {
      _accessToken = await _storage.read(key: _accessKey);
      _refreshToken = await _storage.read(key: _refreshKey);
    }
    return _accessToken != null && _refreshToken != null;
  }

  /// 刷新 access token（供 web 平台手动调用，Dio 拦截器自动调用）
  Future<void> refreshAccessToken() async {
    final resp = await Dio(BaseOptions(baseUrl: AppConfig.baseUrl))
        .post('/api/auth/refresh', data: {'refresh_token': _refreshToken});
    final access = resp.data['access_token'] as String?;
    final refresh = resp.data['refresh_token'] as String?;
    if (access != null && refresh != null) {
      _accessToken = access;
      _refreshToken = refresh;
      if (kIsWeb) {
        _memoryFallback[_accessKey] = access;
        _memoryFallback[_refreshKey] = refresh;
      } else {
        await _storage.write(key: _accessKey, value: access);
        await _storage.write(key: _refreshKey, value: refresh);
      }
    } else {
      await clearTokens();
    }
    _isRefreshing = false;
  }

  String? get accessToken => _accessToken;

  /// 返回适合 SSE 流式响应的 Options（非 Web 平台使用）
  Options streamOptions() => Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 10),
      );

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);
  Future<Response> post(String path, {dynamic data}) => dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) => dio.put(path, data: data);
  Future<Response> delete(String path) => dio.delete(path);
}

class _TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ApiClient().accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
