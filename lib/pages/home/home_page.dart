import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/api_client.dart';
import '../../widgets/login_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Room info state
  Map<String, dynamic>? _roomData;
  bool _roomLoading = true;
  String? _roomError;

  @override
  void initState() {
    super.initState();
    _fetchRoomInfo();
  }

  Future<void> _fetchRoomInfo() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) {
      setState(() {
        _roomLoading = false;
        _roomError = null;
      });
      return;
    }
    setState(() {
      _roomLoading = true;
      _roomError = null;
    });
    try {
      final resp = await ApiClient().get('/api/rooms/my-room');
      setState(() {
        _roomData = resp.data as Map<String, dynamic>;
        _roomLoading = false;
      });
    } catch (e) {
      final is404 = e.toString().contains('404');
      setState(() {
        _roomLoading = false;
        _roomError = is404 ? '暂无入住房间' : '信息加载失败';
      });
    }
  }

  String _mapRoomType(String? type) {
    switch (type) {
      case 'big_bed':
        return '大床房';
      case 'twin':
        return '双床房';
      case 'suite':
        return '套房';
      default:
        return type ?? '未知';
    }
  }

  String _mapRoomStatus(String? status) {
    switch (status) {
      case 'occupied':
        return '已入住';
      case 'vacant':
        return '空闲';
      default:
        return status ?? '未知';
    }
  }

  Future<void> _callHotel() async {
    final uri = Uri.parse('tel:13800000002');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap() async {
    final uri = Uri.parse(
        'https://maps.apple.com/?ll=39.9042,116.4074&q=智宿云大酒店');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final fallback = Uri.parse('geo:39.9042,116.4074?q=智宿云大酒店');
      if (await canLaunchUrl(fallback)) {
        await launchUrl(fallback);
      }
    }
  }

  bool get _isLoggedIn =>
      context.watch<AuthBloc>().state.status == AuthStatus.authenticated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Section A: Banner
          _buildBanner(),
          // Section B: Welcome Card (only when logged in)
          if (_isLoggedIn) _buildWelcomeCard(),
          // Section C: Highlight Cards
          _buildHighlightCards(),
          // Section D: Facilities
          _buildFacilities(),
          // Section E: Bottom Info
          _buildBottomInfo(),
        ],
      ),
    );
  }

  // ── Section A: Banner ──
  Widget _buildBanner() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF1677FF)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              '智宿云大酒店',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '智慧 · 舒适 · 人文',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Text('🗺️', style: TextStyle(fontSize: 18)),
                      label: const Text('一键导航'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1677FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _openMap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Text('📞', style: TextStyle(fontSize: 18)),
                      label: const Text('一键拨号'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF52C41A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _callHotel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section B: Welcome Card ──
  Widget _buildWelcomeCard() {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState.name ?? '用户';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '欢迎回来，$userName 👋',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRoomInfo(),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    if (_roomLoading) {
      return Row(
        children: [
          Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }
    if (_roomError != null) {
      return Text(
        _roomError!,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      );
    }
    if (_roomData == null) {
      return const SizedBox.shrink();
    }
    final roomNumber = _roomData!['room_number'] ?? '--';
    final roomType = _mapRoomType(_roomData!['room_type'] as String?);
    final roomStatus = _mapRoomStatus(_roomData!['room_status'] as String?);
    return Text(
      '房间 $roomNumber · $roomType · $roomStatus',
      style: const TextStyle(fontSize: 13, color: Colors.grey),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'emoji': '🤖', 'label': 'AI管家', 'path': '/ai-chat'},
      {'emoji': '💡', 'label': '控房', 'path': '/room-control'},
      {'emoji': '📋', 'label': '工单', 'path': '/work-orders'},
      {'emoji': '📄', 'label': '账单', 'path': '/my'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () => context.go(a['path']!),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(a['emoji']!, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                a['label']!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Section C: Highlight Cards ──
  Widget _buildHighlightCards() {
    final highlights = [
      {
        'emoji': '🤖',
        'title': 'AI智能管家',
        'desc': '一句话送水、报修、调温',
        'path': '/ai-chat',
      },
      {
        'emoji': '🦾',
        'title': '机器人送物',
        'desc': '自动配送，30分钟送达',
        'path': '/work-orders',
      },
      {
        'emoji': '💡',
        'title': '智能客房',
        'desc': '手机控灯光·窗帘·空调',
        'path': '/room-control',
      },
      {
        'emoji': '🏊',
        'title': '空中花园',
        'desc': '泳池+健身房+行政酒廊',
        'path': '/facility',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ 酒店亮点',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: highlights.length,
            itemBuilder: (context, index) {
              final item = highlights[index];
              return _buildHighlightCard(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(Map<String, String> item) {
    return GestureDetector(
      onTap: () {
        if (!_isLoggedIn) {
          LoginBottomSheet.show(context);
        } else {
          context.push(item['path']!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item['emoji']!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              item['title']!,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              item['desc']!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section D: Facilities ──
  Widget _buildFacilities() {
    final facilities = [
      {
        'icon': '🏋️',
        'name': '24H健身房',
        'time': '营业至24:00',
        'price': '免费',
        'color': const Color(0xFF1677FF),
      },
      {
        'icon': '🏊',
        'name': '无边泳池',
        'time': '水温26°C',
        'price': '免费',
        'color': const Color(0xFF13C2C2),
      },
      {
        'icon': '🍽️',
        'name': '中西餐厅',
        'time': '07:00-22:00',
        'price': '收费',
        'color': const Color(0xFFFA8C16),
      },
      {
        'icon': '👕',
        'name': '自助洗衣房',
        'time': '24小时',
        'price': '¥15/次',
        'color': const Color(0xFF722ED1),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏢 配套设施',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...facilities.map((f) => _buildFacilityCard(f)),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> f) {
    return GestureDetector(
      onTap: () => context.push('/facility', extra: f),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: f['color'] as Color, width: 4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Text(f['icon'] as String, style: const TextStyle(fontSize: 24)),
            title: Text(
              f['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('${f['time']} · ${f['price']}'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // ── Section E: Bottom Info ──
  Widget _buildBottomInfo() {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '📍 北京市朝阳区建国路100号',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Text('🗺️', style: TextStyle(fontSize: 18)),
                  label: const Text('一键导航'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _openMap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Text('📞', style: TextStyle(fontSize: 18)),
                  label: const Text('一键拨号'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52C41A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _callHotel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
