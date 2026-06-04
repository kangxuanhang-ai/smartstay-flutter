import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class FaceLoginPage extends StatefulWidget {
  const FaceLoginPage({super.key});
  @override
  State<FaceLoginPage> createState() => _FaceLoginPageState();
}

class _FaceLoginPageState extends State<FaceLoginPage> {
  CameraController? _controller;
  bool _initialized = false;
  String? _cameraError;
  int _attemptCount = 0;

  // Colors
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = '未检测到摄像头');
        return;
      }
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(frontCamera, ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() { _initialized = true; _cameraError = null; });
    } catch (e) {
      if (mounted) setState(() => _cameraError = '摄像头初始化失败');
    }
  }

  Future<void> _capture() async {
    if (_attemptCount >= 3) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    final xFile = await _controller!.takePicture();
    final bytes = await xFile.readAsBytes();
    if (mounted) {
      context.read<AuthBloc>().add(AuthFaceLoginRequested(bytes));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF111128), Color(0xFF0a0a1e)],
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              context.go('/home');
            } else if (state.status == AuthStatus.passwordChangeRequired) {
              context.go('/change-password');
            } else if (state.status == AuthStatus.unauthenticated && state.error != null) {
              if (mounted) setState(() => _attemptCount++);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            // Camera error state
            if (_cameraError != null) {
              return SafeArea(
                child: Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        onPressed: () => context.go('/login'),
                      ),
                      title: const Text('刷脸登录', style: TextStyle(color: Colors.white)),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 16),
                            Text(_cameraError!, style: const TextStyle(color: _muted, fontSize: 14)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() { _cameraError = null; _initialized = false; });
                                _initCamera();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: _blue),
                              child: const Text('重试', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Loading state
            if (!_initialized) {
              return SafeArea(
                child: Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        onPressed: () => context.go('/login'),
                      ),
                      title: const Text('刷脸登录', style: TextStyle(color: Colors.white)),
                    ),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator(color: _blue)),
                    ),
                  ],
                ),
              );
            }

            // Camera preview with face guide
            return SafeArea(
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                      onPressed: () => context.go('/login'),
                    ),
                    title: const Text('刷脸登录', style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Camera preview
                        CameraPreview(_controller!),
                        // Face guide overlay
                        CustomPaint(
                          size: Size.infinite,
                          painter: _FaceGuidePainter(),
                        ),
                        // Hint text
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.38 + MediaQuery.of(context).size.width * 0.275 + 16,
                          child: const Text('请将面部对准圆框', style: TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                        ),
                      ],
                    ),
                  ),
                  // Bottom controls
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF111128),
                      border: Border(top: BorderSide(color: _card)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_attemptCount >= 3)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text('尝试次数已达上限，请使用密码登录',
                              style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                          ),
                        SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _attemptCount >= 3 ? _card : _blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: (_attemptCount >= 3 || state.status == AuthStatus.faceLoginLoading)
                                ? null
                                : _capture,
                            child: state.status == AuthStatus.faceLoginLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('开始刷脸', style: TextStyle(fontSize: 16, color: _attemptCount >= 3 ? _muted : Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('返回密码登录', style: TextStyle(color: _muted)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent mask
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circleCenter = Offset(size.width / 2, size.height * 0.38);
    final circleRadius = size.width * 0.275;
    final circlePath = Path()..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius));
    final maskPath = Path.combine(PathOperation.difference, fullPath, circlePath);
    canvas.drawPath(maskPath, maskPaint);

    // Circle border
    final borderPaint = Paint()
      ..color = const Color(0xFF2563eb)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(circleCenter, circleRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
