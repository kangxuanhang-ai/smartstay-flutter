enum AuthStatus { initial, loading, authenticated, unauthenticated, passwordChangeRequired }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? name;
  final String? idCard;
  final String? phone;
  final String? role;
  final bool isFirstLogin;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.name,
    this.idCard,
    this.phone,
    this.role,
    this.isFirstLogin = true,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? name,
    String? idCard,
    String? phone,
    String? role,
    bool? isFirstLogin,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      idCard: idCard ?? this.idCard,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      error: error,
    );
  }
}
