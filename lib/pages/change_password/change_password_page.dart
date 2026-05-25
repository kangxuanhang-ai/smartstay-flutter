import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('🔐 安全设置'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('首次登录 · 请修改密码', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('修改完成前无法访问其他页面', style: TextStyle(fontSize: 13, color: Colors.red)),
                  const SizedBox(height: 32),
                  _input(_oldController, '旧密码（初始密码123456）'),
                  const SizedBox(height: 16),
                  _input(_newController, '新密码（至少6位）', onSubmit: _submit),
                  const SizedBox(height: 16),
                  _input(_confirmController, '确认新密码', onSubmit: _submit),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, height: 46, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23))),
                    onPressed: state.status == AuthStatus.loading ? null : _submit,
                    child: const Text('✅ 确认修改并进入应用', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, {VoidCallback? onSubmit}) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
      onSubmitted: (_) => onSubmit?.call(),
    );
  }
}
