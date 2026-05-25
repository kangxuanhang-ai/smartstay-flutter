import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  void _submit() {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();
    if (id.isEmpty || pw.isEmpty) return;
    context.read<AuthBloc>().add(AuthLoginRequested(idCard: id, password: pw));
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text('🏨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  const Text('智宿云', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('您的智能酒店管家', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Text('住客登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const Text('输入身份证号或手机号登录', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _idController,
                          decoration: const InputDecoration(labelText: '身份证号 / 手机号', hintText: '请输入', border: OutlineInputBorder()),
                          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pwController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: '密码', hintText: '初始密码 123456', border: OutlineInputBorder()),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                            onPressed: state.status == AuthStatus.loading ? null : _submit,
                            child: state.status == AuthStatus.loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('登  录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ],
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
}
