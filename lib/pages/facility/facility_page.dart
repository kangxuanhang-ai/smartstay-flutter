import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FacilityPage extends StatelessWidget {
  const FacilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final facility = GoRouterState.of(context).extra as Map<String, dynamic>? ??
        const {'icon': '🏊', 'name': '无边泳池'};

    return Scaffold(
      appBar: AppBar(title: Text('${facility['icon']} ${facility['name']}'), backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
      body: ListView(
        children: [
          Container(
            height: 180,
            color: const Color(0xFFE6F7FF),
            alignment: Alignment.center,
            child: Text(facility['icon']?.toString() ?? '🏊', style: const TextStyle(fontSize: 64)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoCard('🕐 营业时间', facility['time']?.toString() ?? '06:00 - 23:00'),
                const SizedBox(height: 12),
                _InfoCard('💰 收费标准', facility['price']?.toString() ?? '免费（住客专用）'),
                const SizedBox(height: 12),
                _InfoCard('🌡️ 实时动态', facility['dynamic']?.toString() ?? '水温 26°C · 空闲'),
                const SizedBox(height: 12),
                _InfoCard('📋 温馨提示', '请着泳衣，1.4m以下儿童需家长陪同'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF0F0F0))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
