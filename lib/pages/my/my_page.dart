import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/room/room_bloc.dart';
import '../../blocs/room/room_event.dart';
import '../../blocs/room/room_state.dart';
import '../../core/api_client.dart';
import 'package:go_router/go_router.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  Map<String, dynamic>? _currentOrder;
  Map<String, dynamic>? _billData;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth.status == AuthStatus.authenticated) {
      context.read<RoomBloc>().add(RoomFetched());
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthBloc>().state;
    if (auth.status != AuthStatus.authenticated) return;
    try {
      final orderResp = await ApiClient().get('/api/orders/current');
      _currentOrder = orderResp.data as Map<String, dynamic>?;
      if (_currentOrder != null) {
        final billResp = await ApiClient().get('/api/orders/${_currentOrder!['id']}/bill');
        _billData = billResp.data as Map<String, dynamic>?;
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  bool get _isLoggedIn => context.read<AuthBloc>().state.status == AuthStatus.authenticated;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) _loadData();
      },
      child: Scaffold(
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
                const Text('我的', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 20),
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildMenuList(),
                if (_isLoggedIn) ...[
                  const SizedBox(height: 20),
                  _buildLogoutButton(),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile Card ──
  Widget _buildProfileCard() {
    final name = _isLoggedIn ? (context.read<AuthBloc>().state.name ?? '用户') : '游客';
    final roomState = context.watch<RoomBloc>().state;
    final roomNumber = roomState.roomNumber;
    final roomType = roomState.roomType;

    return GestureDetector(
      onTap: () {
        if (!_isLoggedIn) context.go('/login');
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _blue, width: 4),
                color: _card,
              ),
              child: Center(
                child: Text(name.isNotEmpty ? name.substring(0, 1) : '?',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    roomNumber.isNotEmpty
                      ? '$roomNumber 房间 · ${_mapRoomType(roomType)}'
                      : _isLoggedIn ? '暂无入住房间' : '登录后享受完整入住服务',
                    style: const TextStyle(fontSize: 13, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Menu List ──
  Widget _buildMenuList() {
    final items = [
      (Icons.receipt_long_outlined, '我的订单', () {}),
      (Icons.payment_outlined, '我的账单', () { context.go('/bill-detail'); }),
      (Icons.star_outline, '我的收藏', () {}),
      (Icons.person_outline, '常用信息', () {}),
      (Icons.settings_outlined, '设置', () {}),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(item.$1, color: _muted, size: 22),
                  title: Text(item.$2, style: const TextStyle(fontSize: 15, color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: _muted, size: 20),
                  onTap: item.$3,
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 56, color: Color(0xFF374151)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Logout Button ──
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF374151)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          showDialog(context: context, builder: (ctx) => AlertDialog(
            backgroundColor: _card,
            title: const Text('确认退出', style: TextStyle(color: Colors.white)),
            content: const Text('确定要退出登录吗？', style: TextStyle(color: _muted)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: _muted))),
              TextButton(onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                Navigator.pop(ctx);
              }, child: const Text('退出', style: TextStyle(color: Colors.redAccent))),
            ],
          ));
        },
        child: const Text('退出登录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  String _mapRoomType(String? type) {
    switch (type) {
      case 'big_bed': return '大床房';
      case 'twin': return '双床房';
      case 'suite': return '套房';
      default: return type ?? '';
    }
  }
}
