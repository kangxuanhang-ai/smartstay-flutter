import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  Future<void> _openNativeMap() async {
    final uri = Uri.parse('https://maps.apple.com/?ll=39.9042,116.4074&q=智宿云大酒店');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🗺️ 酒店位置导航'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            height: 300,
            color: const Color(0xFFE8F4F8),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text('智宿云大酒店', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('东经 116.40° 北纬 39.90°', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('酒店地址', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 4),
                const Text('北京市朝阳区建国路100号智宿云大厦', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Text('🗺️', style: TextStyle(fontSize: 20)),
                    label: const Text('唤起手机地图导航', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    onPressed: _openNativeMap,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Text('📞', style: TextStyle(fontSize: 20)),
                    label: const Text('致电前台', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF52C41A), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    onPressed: () async {
                      final uri = Uri.parse('tel:13800000002');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
