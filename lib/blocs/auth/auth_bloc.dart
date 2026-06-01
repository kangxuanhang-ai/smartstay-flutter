import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<Object, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthChangePasswordRequested>(_onChangePassword);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthFetchUserRequested>(_onFetchUser);
    on<AuthBootstrapRequested>(_onBootstrap);
    on<AuthFaceLoginRequested>(_onFaceLogin);
  }

  final _api = ApiClient();

  Future<void> _onBootstrap(AuthBootstrapRequested e, Emitter<AuthState> emit) async {
    final restored = await _api.restoreTokens();
    if (!restored) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    try {
      final me = await _api.get('/api/auth/me');
      final user = me.data as Map<String, dynamic>;
      emit(AuthState(
        status: user['is_first_login'] == true ? AuthStatus.passwordChangeRequired : AuthStatus.authenticated,
        userId: user['id'], name: user['name'], idCard: user['id_card'],
        phone: user['phone'], role: user['role'], isFirstLogin: user['is_first_login'] == true,
      ));
    } catch (_) {
      await _api.clearTokens();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      // ignore: avoid_print
      print('[AUTH] POST /api/auth/login id_card=${event.idCard}');
      final resp = await _api.post('/api/auth/login', data: {
        'id_card': event.idCard, 'password': event.password,
      });
      // ignore: avoid_print
      print('[AUTH] response: ${resp.statusCode} ${resp.data}');
      _api.setTokens(resp.data['access_token'], resp.data['refresh_token']);
      final me = await _api.get('/api/auth/me');
      final user = me.data as Map<String, dynamic>;
      emit(AuthState(
        status: user['is_first_login'] == true ? AuthStatus.passwordChangeRequired : AuthStatus.authenticated,
        userId: user['id'], name: user['name'], idCard: user['id_card'],
        phone: user['phone'], role: user['role'], isFirstLogin: user['is_first_login'] == true,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[AUTH] ERROR: $e');
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: '登录失败: $e'));
    }
  }

  Future<void> _onChangePassword(AuthChangePasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _api.post('/api/auth/change-password', data: {
        'old_password': event.oldPassword, 'new_password': event.newPassword,
        'confirm_password': event.confirmPassword,
      });
      emit(state.copyWith(status: AuthStatus.authenticated, isFirstLogin: false));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.passwordChangeRequired, error: '密码修改失败'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _api.clearTokens();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onFetchUser(AuthFetchUserRequested event, Emitter<AuthState> emit) async {
    try {
      final me = await _api.get('/api/auth/me');
      final user = me.data as Map<String, dynamic>;
      emit(AuthState(
        status: user['is_first_login'] == true ? AuthStatus.passwordChangeRequired : AuthStatus.authenticated,
        userId: user['id'], name: user['name'], idCard: user['id_card'],
        phone: user['phone'], role: user['role'], isFirstLogin: user['is_first_login'] == true,
      ));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onFaceLogin(AuthFaceLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.faceLoginLoading, error: null));
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(event.imageBytes, filename: 'face.jpg'),
      });
      final response = await _api.post('/api/face/search', data: formData);
      final data = response.data;
      _api.setTokens(data['access_token'], data['refresh_token']);
      final userResp = await _api.get('/api/auth/me');
      final user = userResp.data;
      emit(AuthState(
        status: AuthStatus.authenticated,
        userId: user['id'],
        name: user['name'],
        idCard: user['id_card'],
        phone: user['phone'] ?? '',
        role: user['role'] ?? 'guest',
        isFirstLogin: user['is_first_login'] ?? false,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: '刷脸登录失败'));
    }
  }
}
