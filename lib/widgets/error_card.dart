import 'package:flutter/material.dart';

class ErrorCardWidget extends StatefulWidget {
  final String type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onDismiss;

  const ErrorCardWidget({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.onDismiss,
  });

  @override
  State<ErrorCardWidget> createState() => _ErrorCardWidgetState();
}

class _ErrorCardWidgetState extends State<ErrorCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: _getColor(widget.type), width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getIcon(widget.type), color: _getColor(widget.type), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    if (widget.onDismiss != null)
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.message, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4)),
                if (widget.actionLabel != null || widget.secondaryLabel != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.secondaryLabel != null) ...[
                        OutlinedButton(
                          onPressed: widget.onSecondary,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9CA3AF),
                            side: const BorderSide(color: Color(0xFF374151)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(widget.secondaryLabel!, style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.actionLabel != null)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onAction,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(widget.actionLabel!, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'network': return Icons.wifi_off;
      case 'auth': return Icons.lock_outline;
      case 'server': return Icons.cloud_off;
      case 'asr': return Icons.mic_off;
      case 'forbidden': return Icons.lock;
      default: return Icons.error_outline;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'network': return const Color(0xFFEF4444);
      case 'auth': return const Color(0xFFF59E0B);
      case 'server': return const Color(0xFFEF4444);
      case 'asr': return const Color(0xFF8B5CF6);
      case 'forbidden': return const Color(0xFF3B82F6);
      default: return const Color(0xFFEF4444);
    }
  }
}
