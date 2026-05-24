import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingQueue = [];

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_TokenInterceptor());

    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          final req = error.requestOptions;
          if (!_isRefreshing) {
            _isRefreshing = true;
            try {
              await _refreshAccessToken();
              req.headers['Authorization'] = 'Bearer $_accessToken';
              _pendingQueue.forEach((r) {
                r.headers['Authorization'] = 'Bearer $_accessToken';
                dio.fetch(r).then((v) {}).catchError((_) {});
              });
              _pendingQueue.clear();
              final resp = await dio.fetch(req);
              return handler.resolve(resp);
            } catch (e) {
              _pendingQueue.clear();
              _isRefreshing = false;
              clearTokens();
              return handler.next(error);
            }
          } else {
            _pendingQueue.add(req);
            return;
          }
        }
        return handler.next(error);
      },
    ));
  }

  void setTokens(String access, String refresh) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Future<void> _refreshAccessToken() async {
    final resp = await Dio(BaseOptions(baseUrl: AppConfig.baseUrl))
        .post('/api/auth/refresh', data: {'refresh_token': _refreshToken});
    _accessToken = resp.data['access_token'];
    _refreshToken = resp.data['refresh_token'];
    _isRefreshing = false;
  }

  String? get accessToken => _accessToken;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response> delete(String path) =>
      dio.delete(path);
}

class _TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ApiClient().accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
