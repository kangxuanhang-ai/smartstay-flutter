import 'package:flutter/material.dart';

class FacilityPage extends StatefulWidget {
  const FacilityPage({super.key});

  @override
  State<FacilityPage> createState() => _FacilityPageState();
}

class _FacilityPageState extends State<FacilityPage> {
  int _selectedCategory = 0;

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  final _categories = ['全部', '休闲娱乐', '餐饮美食', '商务会议'];

  final _facilities = [
    {
      'name': '无边泳池',
      'status': '开放中',
      'statusColor': Color(0xFF4ade80),
      'hours': '06:00-22:00',
      'location': '顶楼',
      'tags': ['景观极佳', '恒温'],
      'action': '预约',
      'icon': Icons.pool,
    },
    {
      'name': '健身房',
      'status': '开放中',
      'statusColor': Color(0xFF4ade80),
      'hours': '06:00-22:00',
      'location': '2楼',
      'tags': ['专业器材'],
      'action': '预约',
      'icon': Icons.fitness_center,
    },
    {
      'name': '早餐厅',
      'status': '即将结束',
      'statusColor': Color(0xFFfb923c),
      'hours': '07:00-10:00',
      'location': '1楼',
      'tags': ['自助餐', '中西结合'],
      'action': '查看',
      'icon': Icons.restaurant,
    },
    {
      'name': '会议室',
      'status': '可预订',
      'statusColor': Color(0xFF60a5fa),
      'hours': '08:00-22:00',
      'location': '3楼',
      'tags': ['投影设备', '白板'],
      'action': '预约',
      'icon': Icons.meeting_room,
    },
  ];

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
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('酒店设施', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                  Icon(Icons.search, color: _muted, size: 24),
                ],
              ),
              const SizedBox(height: 20),

              // ── Category Filters ──
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final isActive = _selectedCategory == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isActive ? _blue : _card,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(_categories[i], style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : _muted)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Facility Cards ──
              ..._facilities.map((f) => _buildFacilityCard(f)),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF374151)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text('查看全部设施', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Icon placeholder (instead of image)
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF374151), borderRadius: BorderRadius.circular(10)),
            child: Icon(f['icon'] as IconData, color: _muted, size: 36),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(f['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (f['statusColor'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(f['status'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: f['statusColor'] as Color)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(f['hours'] as String, style: const TextStyle(fontSize: 12, color: _muted)),
                Text('位置: ${f['location']}', style: const TextStyle(fontSize: 12, color: _muted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...(f['tags'] as List).map((tag) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(6)),
                      child: Text(tag as String, style: const TextStyle(fontSize: 10, color: _muted)),
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
            child: Text(f['action'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
