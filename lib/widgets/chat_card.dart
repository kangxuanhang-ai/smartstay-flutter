import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/chat_card.dart';

class ChatCardWidget extends StatefulWidget {
  final ChatCard card;
  final bool isStreaming;

  const ChatCardWidget({
    super.key,
    required this.card,
    required this.isStreaming,
  });

  @override
  State<ChatCardWidget> createState() => _ChatCardWidgetState();
}

class _ChatCardWidgetState extends State<ChatCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _sizeAnim;

  static const _cardBg = Color(0xFF1f2937);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _sizeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.card.type.name;
    final title = widget.card.title;
    final subtitle = widget.card.subtitle;
    final metadata = widget.card.metadata;
    final isError = type == 'error';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SizeTransition(
        sizeFactor: _sizeAnim,
        child: GestureDetector(
          onTap: () => _onTap(context, type),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isError
                    ? const Color(0xFFef4444).withOpacity(0.5)
                    : const Color(0xFF374151),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(12),
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
                                fontWeight: FontWeight.w600,
                                color: isError ? const Color(0xFFfca5a5) : Colors.white,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9ca3af)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_hasNavigation(type))
                        const Icon(Icons.chevron_right, color: Color(0xFF6b7280), size: 18),
                    ],
                  ),
                ),
                // Rich content
                if (type == 'deviceControl' && metadata != null)
                  _buildDeviceControlContent(metadata),
                if (type == 'workOrder' && metadata != null)
                  _buildWorkOrderContent(metadata),
                if (type == 'pricing' && metadata != null)
                  _buildPricingContent(metadata),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Device Control Content ──
  Widget _buildDeviceControlContent(Map<String, dynamic> meta) {
    final device = meta['device'] as String? ?? '';
    final value = meta['value'];
    final deviceStates = meta['device_states'] as Map<String, dynamic>?;

    if (device == 'ac_temp' && value != null) {
      final temp = (value is int) ? value.toDouble() : (value is double ? value : 24.0);
      return _buildTempSlider(temp);
    }
    if (device == 'curtain' && value != null) {
      final curtain = (value is int) ? value.toDouble() : (value is double ? value : 80.0);
      return _buildCurtainBar(curtain);
    }
    if (device.contains('light') && deviceStates != null) {
      return _buildLightStatus(deviceStates);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTempSlider(double temp) {
    final ratio = (temp - 16) / 14;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFF2D2D44)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.thermostat, size: 14, color: Color(0xFF60a5fa)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF374151),
                    valueColor: AlwaysStoppedAnimation(
                      Color.lerp(const Color(0xFF3B82F6), const Color(0xFFEF4444), ratio),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${temp.round()}°C',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('16°C', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              Text('30°C', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurtainBar(double value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFF2D2D44)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.curtains, size: 14, color: Color(0xFF60a5fa)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF374151),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF60a5fa)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${value.round()}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLightStatus(Map<String, dynamic> states) {
    final lights = [
      _LightInfo('bedside_light', '床头灯', Icons.lightbulb_outline),
      _LightInfo('bedroom_light', '卧室灯', Icons.lightbulb),
      _LightInfo('living_light', '客厅灯', Icons.light),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFF2D2D44)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: lights.map((light) {
              final isOn = states[light.key] == true || states[light.key] == 'on';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOn ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOn ? const Color(0xFF10B981).withOpacity(0.4) : const Color(0xFF374151),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(light.icon, size: 18, color: isOn ? const Color(0xFF10B981) : const Color(0xFF6B7280)),
                    const SizedBox(height: 4),
                    Text(light.label, style: TextStyle(fontSize: 10, color: isOn ? const Color(0xFF10B981) : const Color(0xFF6B7280))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Work Order Content ──
  Widget _buildWorkOrderContent(Map<String, dynamic> meta) {
    final status = meta['status'] as String? ?? 'submitted';
    final orderId = meta['order_id'] as String? ?? '';

    final steps = [
      _ProgressStep('submitted', '已提交', Icons.check_circle_outline),
      _ProgressStep('processing', '处理中', Icons.hourglass_top),
      _ProgressStep('completed', '已完成', Icons.task_alt),
    ];

    var currentIdx = steps.indexWhere((s) => s.key == status);
    if (currentIdx < 0) currentIdx = 0; // fallback to first step

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFF2D2D44)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final stepIdx = i ~/ 2;
                final isCompleted = stepIdx < currentIdx;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF374151),
                  ),
                );
              }
              // Step circle
              final stepIdx = i ~/ 2;
              final step = steps[stepIdx];
              final isActive = stepIdx == currentIdx;
              final isCompleted = stepIdx < currentIdx;

              return Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? const Color(0xFF10B981)
                          : isCompleted
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : const Color(0xFF1A1A2E),
                      border: Border.all(
                        color: isActive || isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF374151),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step.icon,
                      size: 14,
                      color: isActive
                          ? Colors.white
                          : isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive
                          ? const Color(0xFF10B981)
                          : isCompleted
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
          if (orderId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '工单号: ${orderId.substring(0, orderId.length > 12 ? 12 : orderId.length)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Pricing Content ──
  Widget _buildPricingContent(Map<String, dynamic> meta) {
    final currentPrice = (meta['current_price'] as num?)?.toDouble() ?? 0;
    final suggestedPrice = (meta['suggested_price'] as num?)?.toDouble() ?? 0;
    final reason = meta['reason'] as String? ?? '';

    if (currentPrice <= 0 && suggestedPrice <= 0) return const SizedBox.shrink();

    final maxPrice = currentPrice > suggestedPrice ? currentPrice : suggestedPrice;
    if (maxPrice <= 0) return const SizedBox.shrink();
    final changePercent = currentPrice > 0
        ? ((suggestedPrice - currentPrice) / currentPrice * 100)
        : 0;
    final isIncrease = changePercent > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFF2D2D44)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Current price bar
              Expanded(
                child: Column(
                  children: [
                    const Text('当前价格', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 6),
                    Container(
                      height: (currentPrice / maxPrice * 60).clamp(20, 60),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Text(
                          '¥${currentPrice.round()}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF60a5fa)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Suggested price bar
              Expanded(
                child: Column(
                  children: [
                    const Text('AI 建议价', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 6),
                    Container(
                      height: (suggestedPrice / maxPrice * 60).clamp(20, 60),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Text(
                          '¥${suggestedPrice.round()}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFa78bfa)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isIncrease ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isIncrease ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                '${isIncrease ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isIncrease ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '原因: $reason',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(String type) {
    if (widget.isStreaming) {
      return const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60a5fa)),
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
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 18),
    );
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

class _LightInfo {
  final String key;
  final String label;
  final IconData icon;
  const _LightInfo(this.key, this.label, this.icon);
}

class _ProgressStep {
  final String key;
  final String label;
  final IconData icon;
  const _ProgressStep(this.key, this.label, this.icon);
}
