class AuthBootstrapRequested {}

class AuthLoginRequested {
  final String idCard;
  final String password;

  const AuthLoginRequested({required this.idCard, required this.password});
}

class AuthChangePasswordRequested {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const AuthChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}

class AuthLogoutRequested {}

class AuthFetchUserRequested {}

class AuthFaceLoginRequested {
  final List<int> imageBytes;
  AuthFaceLoginRequested(this.imageBytes);
}
