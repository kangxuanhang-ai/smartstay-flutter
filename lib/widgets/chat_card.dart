import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/chat_card.dart';

class ChatCardWidget extends StatelessWidget {
  final ChatCard card;
  final bool isStreaming;

  const ChatCardWidget({
    super.key,
    required this.card,
    required this.isStreaming,
  });

  static const _cardBg = Color(0xFF1f2937);

  @override
  Widget build(BuildContext context) {
    final type = card.type.name;
    final title = card.title;
    final isError = type == 'error';

    return GestureDetector(
      onTap: () => _onTap(context, type),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: isError
              ? Border.all(color: const Color(0xFFef4444), width: 1)
              : Border.all(color: const Color(0xFF374151), width: 1),
        ),
        child: Row(
          children: [
            _buildIcon(type),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isError ? const Color(0xFFfca5a5) : Colors.white,
                    ),
                  ),
                  if (_getSubtitle(type) != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _getSubtitle(type)!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9ca3af),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_hasNavigation(type))
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF6b7280),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    if (isStreaming) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF60a5fa),
        ),
      );
    }
    final iconData = switch (type) {
      'workOrder' => Icons.assignment_outlined,
      'deviceControl' => Icons.devices_outlined,
      'pricing' => Icons.attach_money,
      'error' => Icons.error_outline,
      _ => Icons.check_circle_outline,
    };
    final color = switch (type) {
      'error' => const Color(0xFFef4444),
      'workOrder' => const Color(0xFFf59e0b),
      'deviceControl' => const Color(0xFF10b981),
      'pricing' => const Color(0xFF8b5cf6),
      _ => const Color(0xFF60a5fa),
    };
    return Icon(iconData, color: color, size: 20);
  }

  String? _getSubtitle(String type) {
    return switch (type) {
      'workOrder' => '点击查看详情',
      'deviceControl' => '设备已更新',
      'pricing' => '待审批',
      'error' => '请重试或联系前台',
      _ => null,
    };
  }

  bool _hasNavigation(String type) {
    return type == 'workOrder' || type == 'deviceControl';
  }

  void _onTap(BuildContext context, String type) {
    switch (type) {
      case 'workOrder':
        context.go('/work-orders');
        break;
      case 'deviceControl':
        context.go('/room-control');
        break;
    }
  }
}
