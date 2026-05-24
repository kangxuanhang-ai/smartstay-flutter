import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<Object, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthChangePasswordRequested>(_onChangePassword);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthFetchUserRequested>(_onFetchUser);
  }

  final _api = ApiClient();

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final resp = await _api.post('/api/auth/login',
          data: {'id_card': event.idCard, 'password': event.password});
      _api.setTokens(resp.data['access_token'], resp.data['refresh_token']);

      final me = await _api.get('/api/auth/me');
      final user = me.data as Map<String, dynamic>;

      emit(AuthState(
        status: user['is_first_login'] == true
            ? AuthStatus.passwordChangeRequired
            : AuthStatus.authenticated,
        userId: user['id'],
        name: user['name'],
        idCard: user['id_card'],
        phone: user['phone'],
        role: user['role'],
        isFirstLogin: user['is_first_login'] == true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: '登录失败，请检查身份证号和密码',
      ));
    }
  }

  Future<void> _onChangePassword(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _api.post('/api/auth/change-password', data: {
        'old_password': event.oldPassword,
        'new_password': event.newPassword,
        'confirm_password': event.confirmPassword,
      });
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isFirstLogin: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: '密码修改失败'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _api.clearTokens();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onFetchUser(
    AuthFetchUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final me = await _api.get('/api/auth/me');
      final user = me.data as Map<String, dynamic>;
      emit(AuthState(
        status: user['is_first_login'] == true
            ? AuthStatus.passwordChangeRequired
            : AuthStatus.authenticated,
        userId: user['id'],
        name: user['name'],
        idCard: user['id_card'],
        phone: user['phone'],
        role: user['role'],
        isFirstLogin: user['is_first_login'] == true,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }
}
