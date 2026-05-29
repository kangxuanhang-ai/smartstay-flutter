// lib/widgets/login_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoginBottomSheet(),
    );
  }

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final _idCardCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _showChangePassword = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _showChangePassword ? _buildChangePasswordSheet() : _buildLoginSheet(),
    );
  }

  Widget _buildLoginSheet() {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
        Align(alignment: Alignment.topRight, child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 26, height: 26,
            decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 14, color: Color(0xFF999999))),
        )),
        const SizedBox(height: 8),
        const Text('🏨', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        const Text('登录智宿云', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        const Text('享受智慧入住体验', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
        const SizedBox(height: 20),
        _buildInputField(label: '身份证号', controller: _idCardCtrl),
        const SizedBox(height: 10),
        _buildInputField(label: '密码', controller: _passwordCtrl, obscure: true),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFFF4D4F), fontSize: 11)),
          const SizedBox(height: 8),
        ],
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
          onPressed: _loading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('立即登录', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 14),
        const Text('还没有账号？请前往前台办理入住', style: TextStyle(fontSize: 10, color: Color(0xFFBBBBBB))),
      ]),
    );
  }

  Widget _buildChangePasswordSheet() {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
        Align(alignment: Alignment.topRight, child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 26, height: 26,
            decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 14, color: Color(0xFF999999))),
        )),
        const SizedBox(height: 8),
        const Text('🔑', style: TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        const Text('修改初始密码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 3),
        const Text('首次登录，请设置新密码', style: TextStyle(fontSize: 9, color: Color(0xFF999999))),
        const SizedBox(height: 14),
        _buildInputField(label: '原密码', controller: _oldPasswordCtrl, obscure: true),
        const SizedBox(height: 8),
        _buildInputField(label: '新密码', controller: _newPasswordCtrl, obscure: true, focus: true),
        const SizedBox(height: 8),
        _buildInputField(label: '确认新密码', controller: _confirmPasswordCtrl, obscure: true),
        const SizedBox(height: 12),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFFF4D4F), fontSize: 11)),
          const SizedBox(height: 8),
        ],
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
          onPressed: _loading ? null : _handleChangePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('确认修改', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    bool focus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: focus ? const Color(0xFFF8FAFF) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: focus ? Border.all(color: const Color(0xFF1677FF), width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: focus ? const Color(0xFF1677FF) : const Color(0xFF999999))),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        ),
      ]),
    );
  }

  Future<void> _handleLogin() async {
    final idCard = _idCardCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (idCard.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入身份证号和密码');
      return;
    }
    if (idCard.length != 18) {
      setState(() => _error = '请输入18位身份证号');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final bloc = context.read<AuthBloc>();
      bloc.add(AuthLoginRequested(idCard: idCard, password: password));
      await bloc.stream.firstWhere((s) =>
        s.status == AuthStatus.authenticated ||
        s.status == AuthStatus.passwordChangeRequired ||
        s.status == AuthStatus.unauthenticated);
      final state = bloc.state;
      if (state.status == AuthStatus.passwordChangeRequired) {
        setState(() { _showChangePassword = true; _loading = false; });
      } else if (state.status == AuthStatus.authenticated) {
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _error = state.error ?? '登录失败，请检查身份证号和密码'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = '网络异常，请重试'; _loading = false; });
    }
  }

  Future<void> _handleChangePassword() async {
    final oldPw = _oldPasswordCtrl.text.trim();
    final newPw = _newPasswordCtrl.text.trim();
    final confirmPw = _confirmPasswordCtrl.text.trim();
    if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      setState(() => _error = '请填写所有字段');
      return;
    }
    if (newPw != confirmPw) {
      setState(() => _error = '两次输入的新密码不一致');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final bloc = context.read<AuthBloc>();
      bloc.add(AuthChangePasswordRequested(oldPassword: oldPw, newPassword: newPw, confirmPassword: confirmPw));
      await bloc.stream.firstWhere((s) =>
        s.status == AuthStatus.authenticated ||
        s.status == AuthStatus.passwordChangeRequired);
      final state = bloc.state;
      if (state.status == AuthStatus.authenticated) {
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _error = state.error ?? '密码修改失败'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = '网络异常，请重试'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _idCardCtrl.dispose();
    _passwordCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }
}
