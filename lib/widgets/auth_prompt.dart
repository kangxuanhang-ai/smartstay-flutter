// lib/widgets/auth_prompt.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthPrompt extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool showAsOverlay;

  const AuthPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.showAsOverlay = true,
  });

  const AuthPrompt.overlay({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  }) : showAsOverlay = true;

  const AuthPrompt.bottomBar({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  }) : showAsOverlay = false;

  @override
  Widget build(BuildContext context) {
    if (showAsOverlay) return _buildOverlay(context);
    return _buildBottomBar(context);
  }

  Widget _buildOverlay(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC).withOpacity(0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text(description, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999), height: 1.6)),
            const SizedBox(height: 20),
            _buildLoginButton(context),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          const SizedBox(height: 12),
          _buildLoginButton(context),
        ]),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1677FF), Color(0xFF4096FF)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: const Color(0xFF1677FF).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Text('立即登录', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
