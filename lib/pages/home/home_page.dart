import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/room/room_bloc.dart';
import '../../blocs/room/room_state.dart';
import '../../core/api_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _roomData;
  bool _roomLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoomInfo();
  }

  Future<void> _fetchRoomInfo() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) {
      setState(() => _roomLoading = false);
      return;
    }
    setState(() => _roomLoading = true);
    try {
      final resp = await ApiClient().get('/api/rooms/my-room');
      setState(() { _roomData = resp.data as Map<String, dynamic>; _roomLoading = false; });
    } catch (e) {
      setState(() => _roomLoading = false);
    }
  }

  bool get _isLoggedIn => context.watch<AuthBloc>().state.status == AuthStatus.authenticated;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return '早上好';
    if (hour >= 12 && hour < 18) return '下午好';
    if (hour >= 18 && hour < 23) return '晚上好';
    return '夜深了';
  }

  String _mapRoomType(String? type) {
    switch (type) {
      case 'big_bed': return '大床房';
      case 'twin': return '双床房';
      case 'suite': return '套房';
      default: return type ?? '';
    }
  }

  // ── Colors (matching HTML prototype) ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  @override
  Widget build(BuildContext context) {
    final name = _isLoggedIn ? (context.watch<AuthBloc>().state.name ?? '用户') : '游客';
    final greeting = _getGreeting();
    final roomNumber = _roomData?['room_number'] ?? '';
    final roomType = _mapRoomType(_roomData?['room_type'] as String?);

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
              // ── Header: Greeting + Avatar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting, $name',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        _roomLoading
                          ? '加载中...'
                          : roomNumber.isNotEmpty
                            ? '$roomNumber 房间${roomType.isNotEmpty ? ' · $roomType' : ''}'
                            : '欢迎入住智宿云大酒店',
                        style: const TextStyle(fontSize: 14, color: _muted)),
                    ],
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _blue, width: 2),
                      color: _card,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── AI Butler Card ──
              _buildAIButlerCard(),

              const SizedBox(height: 24),

              // ── Quick Control Section ──
              const Text('快捷控制', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 12),
              _buildQuickControlGrid(),

              const SizedBox(height: 24),

              // ── Common Services Section ──
              const Text('常用服务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 12),
              _buildServicesGrid(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── AI Butler Card ──
  Widget _buildAIButlerCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_isLoggedIn) { context.go('/login'); return; }
        context.go('/ai-chat');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI 智能管家', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('随时为您服务，帮您解忧', style: TextStyle(fontSize: 13, color: _muted)),
                  const SizedBox(height: 12),
                  Material(
                    color: _blue,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (!_isLoggedIn) { context.go('/login'); return; }
                        context.go('/ai-chat');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('立即呼叫', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: Color(0xFF374151), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF60a5fa), size: 40),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Control Grid ──
  Widget _buildQuickControlGrid() {
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        // 计算灯光数量
        final lightsOn = [state.livingLight, state.bedroomLight, state.bedsideLight].where((l) => l).length;
        final acIcon = state.acCool ? '❄️' : '🔥';

        final items = [
          {'icon': Icons.lightbulb_outline, 'label': '灯光', 'value': '$lightsOn/3', 'color': const Color(0xFFfacc15), 'path': '/room-control'},
          {'icon': Icons.ac_unit, 'label': '空调', 'value': '${state.acTemp}°C $acIcon', 'color': const Color(0xFF60a5fa), 'path': '/room-control'},
          {'icon': Icons.grid_view, 'label': '窗帘', 'value': '${state.curtain}%', 'color': _muted, 'path': '/room-control'},
          {'icon': Icons.living_outlined, 'label': '场景模式', 'value': '', 'color': const Color(0xFFa78bfa), 'path': '/room-control'},
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return Material(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (!_isLoggedIn) { context.go('/login'); return; }
                  context.go(item['path'] as String);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                    const SizedBox(height: 6),
                    Text(item['label'] as String, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    if ((item['value'] as String).isNotEmpty)
                      Text(item['value'] as String, style: TextStyle(fontSize: 10, color: (item['color'] as Color))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Services Grid ──
  Widget _buildServicesGrid() {
    final items = [
      {'icon': Icons.cleaning_services_outlined, 'label': '客房清洁', 'color': const Color(0xFF4ade80)},
      {'icon': Icons.inventory_2_outlined, 'label': '送物服务', 'color': const Color(0xFF60a5fa)},
      {'icon': Icons.checkroom_outlined, 'label': '洗衣服务', 'color': const Color(0xFFf472b6)},
      {'icon': Icons.build_outlined, 'label': '维修服务', 'color': const Color(0xFFfb923c)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Material(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (!_isLoggedIn) { context.go('/login'); return; }
              context.go('/work-orders');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                const SizedBox(height: 6),
                Text(item['label'] as String, style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }
}
