import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
              SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
            );
          }
          if (state.status == AuthStatus.passwordChangeRequired) {
            context.go('/change-password');
          } else if (state.status == AuthStatus.authenticated) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // ── Heading ──
                    const Text('欢迎回来', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('请填写您的会员信息及密码', style: TextStyle(fontSize: 16, color: Color(0xFFd1d5db))),

                    const SizedBox(height: 40),

                    // ── ID Input ──
                    TextField(
                      controller: _idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '请输入账号',
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
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),

                    const SizedBox(height: 16),

                    // ── Password Input ──
                    TextField(
                      controller: _pwController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '密码',
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
                      onSubmitted: (_) => _submit(),
                    ),

                    const SizedBox(height: 8),

                    // ── Forgot password ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('忘记密码?', style: TextStyle(fontSize: 13, color: _blue)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Login Button ──
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
                            : const Text('立即登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 16),
                                        const SizedBox(height: 12),

                    // ── Face Login ──
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/face-login'),
                        icon: const Icon(Icons.face, color: _blue),
                        label: const Text('刷脸登录', style: TextStyle(fontSize: 14, color: _blue)),
                      ),
                    ),

                    // ── Guest mode ──
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('进入游客模式', style: TextStyle(fontSize: 14, color: _muted)),
                      ),
                    ),

                    const SizedBox(height: 4),
                    // ── Register link ──
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('首次登录请点击这里注册', style: TextStyle(fontSize: 13, color: _blue)),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // ── Footer help ──
                    Center(
                      child: Column(
                        children: const [
                          Text('登录遇到问题请联系客服', style: TextStyle(fontSize: 12, color: _muted)),
                          SizedBox(height: 4),
                          Text('· 凭手机号登录', style: TextStyle(fontSize: 12, color: _muted)),
                          SizedBox(height: 2),
                          Text('· 密码登录', style: TextStyle(fontSize: 12, color: _muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
