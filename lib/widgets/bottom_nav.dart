import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  // ── Colors matching HTML prototype ──
  static const _bg = Color(0xFF1a1a3a);
  static const _active = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.home_rounded, '首页'),
      (Icons.lightbulb_outline, '控房'),
      (Icons.smart_toy_outlined, '管家'),
      (Icons.room_service_outlined, '服务'),
      (Icons.person_outline_rounded, '我的'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].$1, color: isActive ? _active : _muted, size: 22),
                      const SizedBox(height: 4),
                      Text(items[i].$2, style: TextStyle(
                        fontSize: 10,
                        color: isActive ? _active : _muted,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
