import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/work_order/work_order_bloc.dart';
import '../../blocs/work_order/work_order_event.dart';
import '../../blocs/work_order/work_order_state.dart';
import '../../widgets/auth_prompt.dart';

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  int _filterIndex = 0; // 0=全部 1=进行中 2=已完成 3=取消

  @override
  void initState() {
    super.initState();
    final isLoggedIn = context.read<AuthBloc>().state.status == AuthStatus.authenticated;
    if (isLoggedIn) {
      context.read<WorkOrderBloc>().add(WorkOrdersFetched());
    }
  }

  String _statusLabel(String s, String type) {
    if (s == 'processing') return type == 'delivery' ? '配送中' : '维修中';
    if (s == 'completed') return '已完成';
    switch (s) {
      case 'submitted': return '已提交';
      case 'accepted': return '已接单';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted': return const Color(0xFF60a5fa);
      case 'accepted': return const Color(0xFF4ade80);
      case 'processing': return const Color(0xFFfacc15);
      case 'completed': return const Color(0xFF4ade80);
      default: return const Color(0xFF9ca3af);
    }
  }

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  bool get _isLoggedIn => context.watch<AuthBloc>().state.status == AuthStatus.authenticated;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('服务追踪', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                    Icon(Icons.search, color: _muted, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Filter Tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['全部', '进行中', '已完成', '取消'].asMap().entries.map((e) {
                    final i = e.key;
                    final label = e.value;
                    final isActive = _filterIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? _blue : _card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(label, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : _muted)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Order List ──
              Expanded(
                child: !_isLoggedIn
                  ? const AuthPrompt.overlay(icon: '🔧', title: '服务工单', description: '登录后查看工单进度')
                  : BlocBuilder<WorkOrderBloc, WorkOrderState>(
                    builder: (context, state) {
                      if (state.loading) {
                        return const Center(child: CircularProgressIndicator(color: _blue));
                      }
                      if (state.error != null) {
                        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(state.error!, style: const TextStyle(color: _muted)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: () => context.read<WorkOrderBloc>().add(WorkOrdersFetched()),
                            style: ElevatedButton.styleFrom(backgroundColor: _blue),
                            child: const Text('重试', style: TextStyle(color: Colors.white))),
                        ]));
                      }

                      final orders = state.orders;
                      if (orders.isEmpty) {
                        return const Center(child: Text('暂无服务请求', style: TextStyle(color: _muted)));
                      }

                      // Filter
                      final filtered = _filterIndex == 0 ? orders : orders.where((wo) {
                        switch (_filterIndex) {
                          case 1: return wo.status == 'submitted' || wo.status == 'accepted' || wo.status == 'processing';
                          case 2: return wo.status == 'completed';
                          case 3: return wo.status == 'cancelled';
                          default: return true;
                        }
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('该分类下暂无工单', style: TextStyle(color: _muted)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final wo = filtered[idx];
                          return _buildTimelineItem(wo, idx < filtered.length - 1);
                        },
                      );
                    },
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(dynamic wo, bool showLine) {
    final color = _statusColor(wo.status);
    final type = wo.type ?? 'delivery';
    final typeLabel = type == 'delivery' ? '送物服务' : '维修服务';
    final steps = _getSteps(wo.status, wo.content ?? '');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline ──
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 4)),
                  child: Icon(
                    type == 'delivery' ? Icons.inventory_2_outlined : Icons.build_outlined,
                    color: Colors.white, size: 22),
                ),
                if (showLine)
                  Expanded(child: Container(width: 2, color: const Color(0xFF374151))),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Card ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('$typeLabel (${wo.content ?? ''})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      Text(_statusLabel(wo.status, type),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('订单号: ${wo.id ?? ''}', style: const TextStyle(fontSize: 11, color: _muted)),
                  const SizedBox(height: 10),

                  // Steps
                  ...steps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: step['done'] ? color : const Color(0xFF374151)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(step['label'], style: TextStyle(
                            fontSize: 12, color: step['done'] ? Colors.white : _muted)),
                        ),
                        Text(step['time'] ?? '', style: const TextStyle(fontSize: 11, color: _muted)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSteps(String status, String content) {
    final now = DateTime.now();
    final base = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    switch (status) {
      case 'submitted':
        return [
          {'label': '已提交', 'done': true, 'time': base},
          {'label': '已接单', 'done': false, 'time': null},
          {'label': '处理中', 'done': false, 'time': null},
          {'label': '已完成', 'done': false, 'time': null},
        ];
      case 'accepted':
        return [
          {'label': '已提交', 'done': true, 'time': base},
          {'label': '已接单', 'done': true, 'time': base},
          {'label': '处理中', 'done': false, 'time': null},
          {'label': '已完成', 'done': false, 'time': null},
        ];
      case 'processing':
        return [
          {'label': '已提交', 'done': true, 'time': base},
          {'label': '已接单', 'done': true, 'time': base},
          {'label': '处理中', 'done': true, 'time': base},
          {'label': '已完成', 'done': false, 'time': null},
        ];
      case 'completed':
        return [
          {'label': '已提交', 'done': true, 'time': base},
          {'label': '已接单', 'done': true, 'time': base},
          {'label': '处理中', 'done': true, 'time': base},
          {'label': '已完成', 'done': true, 'time': base},
        ];
      default:
        return [
          {'label': '已提交', 'done': true, 'time': base},
          {'label': '已接单', 'done': false, 'time': null},
          {'label': '处理中', 'done': false, 'time': null},
          {'label': '已完成', 'done': false, 'time': null},
        ];
    }
  }
}
