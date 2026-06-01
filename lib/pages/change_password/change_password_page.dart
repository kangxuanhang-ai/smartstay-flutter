import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  void _submit() {
    final old = _oldController.text.trim();
    final nw = _newController.text.trim();
    final cf = _confirmController.text.trim();
    if (old.isEmpty || nw.isEmpty || cf.isEmpty) return;
    if (nw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新密码至少6位'), backgroundColor: Colors.red));
      return;
    }
    if (nw != cf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次密码不一致'), backgroundColor: Colors.red));
      return;
    }
    context.read<AuthBloc>().add(AuthChangePasswordRequested(
      oldPassword: old, newPassword: nw, confirmPassword: cf));
  }

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);
  static const _border = Color(0xFF374151);
  static const _muted = Color(0xFF9ca3af);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!), backgroundColor: Colors.red));
          }
          if (state.status == AuthStatus.authenticated) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF111128), Color(0xFF0a0a1e)],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // ── Back button ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(Icons.chevron_left, color: _muted, size: 28),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Heading ──
                  const Text('修改登录密码', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('为了您的账户安全，请设置新密码', style: TextStyle(fontSize: 16, color: Color(0xFFd1d5db))),

                  const SizedBox(height: 40),

                  // ── Old password ──
                  _buildLabel('旧密码'),
                  const SizedBox(height: 8),
                  _buildInput(_oldController, '请输入6~16位原密码'),

                  const SizedBox(height: 20),

                  // ── New password ──
                  _buildLabel('新密码'),
                  const SizedBox(height: 8),
                  _buildInput(_newController, '请输入6~16位新密码'),

                  const SizedBox(height: 20),

                  // ── Confirm password ──
                  _buildLabel('确认新密码'),
                  const SizedBox(height: 8),
                  _buildInput(_confirmController, '请再次输入新密码', onSubmit: _submit),

                  const SizedBox(height: 32),

                  // ── Submit Button ──
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: state.status == AuthStatus.loading ? null : _submit,
                      child: state.status == AuthStatus.loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('确认修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, color: _muted));
  }

  Widget _buildInput(TextEditingController ctrl, String hint, {VoidCallback? onSubmit}) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onSubmitted: (_) => onSubmit?.call(),
    );
  }
}
