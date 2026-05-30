import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/api_client.dart';
import '../../widgets/login_bottom_sheet.dart';

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
    } catch (_) {
      // No active order - ignore
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) _loadData();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('👤 我的'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, auth) {
            if (auth.status == AuthStatus.authenticated) return _buildAuthenticatedView(auth);
            return _buildUnauthView();
          },
        ),
      ),
    );
  }

  Widget _buildUnauthView() {
    return ListView(children: [
      Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF1677FF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
            child: const Center(child: Text('🏨', style: TextStyle(fontSize: 26)))),
          const SizedBox(height: 12),
          const Text('智宿云酒店', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('登录后享受完整入住服务', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => LoginBottomSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16)]),
              child: const Text('立即登录', style: TextStyle(color: Color(0xFF1677FF), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
      _buildSettingsCard(showLogout: false),
    ]);
  }

  Widget _buildAuthenticatedView(AuthState auth) {
    final grandTotal = _billData != null ? ((_billData!['grand_total'] as num?)?.toInt() ?? 0) : 0;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF1677FF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Row(children: [
              Container(width: 48, height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF4096FF), Color(0xFF95DE64)]),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(
                  (auth.name ?? '?').substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('身份证 ${_maskIdCard(auth.idCard ?? '')}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9)),
                Text('手机 ${_maskPhone(auth.phone ?? '')}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9)),
              ]),
            ]),
            if (_currentOrder != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('🏨 当前入住', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                  Text('${_currentOrder!['room_number'] ?? ''}房 · ${_currentOrder!['room_type'] ?? ''}',
                    style: const TextStyle(color: Color(0xFF7FFFA7), fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ]),
        ),
        _buildSectionCard('📋 我的订单', [
          if (_currentOrder != null)
            _buildMenuItem('当前', '${_currentOrder!['room_number'] ?? ''}房', tag: '当前', tagColor: const Color(0xFF1677FF)),
          _buildMenuItem('历史', '暂无记录', tag: '历史', tagColor: const Color(0xFF999999)),
        ]),
        _buildSectionCard('💰 账单消费', [
          _buildMenuItem('当前账单', grandTotal > 0 ? '¥${(grandTotal / 100).toStringAsFixed(0)}' : '暂无账单',
            valueColor: const Color(0xFFFF4D4F)),
        ]),
        _buildSettingsCard(showLogout: true),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(color: Color(0xFFFAFBFC), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
        ...children,
      ]),
    );
  }

  Widget _buildMenuItem(String label, String value, {String? tag, Color? tagColor, Color? valueColor, VoidCallback? onTap}) {
    return InkWell(onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          if (tag != null) ...[
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: tagColor?.withOpacity(0.1) ?? const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
              child: Text(tag, style: TextStyle(fontSize: 8, color: tagColor ?? const Color(0xFF999999), fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF333333)))),
          Text(value, style: TextStyle(fontSize: valueColor != null ? 15 : 10, color: valueColor ?? const Color(0xFF333333), fontWeight: valueColor != null ? FontWeight.w800 : FontWeight.normal)),
          const SizedBox(width: 8),
          const Text('›', style: TextStyle(fontSize: 14, color: Color(0xFFDDDDDD))),
        ])),
    );
  }

  Widget _buildSettingsCard({required bool showLogout}) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(children: [
        if (showLogout) _buildMenuItem('🔑 修改密码', '', onTap: () {}),
        _buildMenuItem('🏨 关于酒店', '', onTap: () {}),
        _buildMenuItem('📞 客服电话', '', onTap: () {}),
        if (showLogout)
          _buildMenuItem('🚪 退出登录', '', valueColor: const Color(0xFFFF4D4F), onTap: () {
            showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text('确认退出'),
              content: const Text('确定要退出登录吗？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                FilledButton(onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.pop(ctx);
                }, child: const Text('退出')),
              ],
            ));
          }),
      ]),
    );
  }

  String _maskIdCard(String idCard) {
    if (idCard.length <= 6) return idCard;
    return '${idCard.substring(0, 4)}****${idCard.substring(idCard.length - 4)}';
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
}
