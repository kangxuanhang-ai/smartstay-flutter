import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('🏠', '首页'),
      ('💡', '控房'),
      ('🤖', '管家'),
      ('📋', '服务'),
      ('👤', '我的'),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1677FF),
      unselectedItemColor: const Color(0xFF8C8C8C),
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: items
          .map((e) => BottomNavigationBarItem(icon: Text(e.$1, style: const TextStyle(fontSize: 20)), label: e.$2))
          .toList(),
    );
  }
}
