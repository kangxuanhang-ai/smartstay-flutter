import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _facilities = const [
    {'icon': '🏋️', 'name': '24H健身房', 'time': '营业至24:00', 'price': '免费'},
    {'icon': '🏊', 'name': '无边泳池', 'time': '水温26°C', 'price': '免费'},
    {'icon': '🍽️', 'name': '中西餐厅', 'time': '07:00-22:00', 'price': '收费'},
    {'icon': '👕', 'name': '自助洗衣房', 'time': '24小时', 'price': '¥15/次'},
  ];

  Future<void> _callHotel() async {
    final uri = Uri.parse('tel:13800000002');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap() async {
    final uri = Uri.parse('https://maps.apple.com/?ll=39.9042,116.4074&q=智宿云大酒店');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final fallback = Uri.parse('geo:39.9042,116.4074?q=智宿云大酒店');
      if (await canLaunchUrl(fallback)) {
        await launchUrl(fallback);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Container(
            height: 180,
            color: const Color(0xFF1A1A2E),
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏨', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text('智宿云大酒店', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('酒店简介', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('智宿云酒店位于市中心黄金地段，提供24小时管家服务，配备智能化客房系统。无论商务出行还是休闲度假，都是您的理想之选。',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Text('🗺️', style: TextStyle(fontSize: 18)),
                        label: const Text('一键导航'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: _openMap,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Text('📞', style: TextStyle(fontSize: 18)),
                        label: const Text('一键拨号'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF52C41A), foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: _callHotel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('配套设施', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () => context.go('/map'), child: const Text('查看地图 →')),
                ]),
                const SizedBox(height: 8),
                ..._facilities.map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Text(f['icon']!, style: const TextStyle(fontSize: 24)),
                    title: Text(f['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${f['time']} · ${f['price']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/facility', extra: f),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
