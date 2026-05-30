import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<WorkOrderBloc>().add(WorkOrdersFetched());
  }

  String _statusLabel(String s, String type) {
    if (s == 'processing') return type == 'delivery' ? '配送中' : '维修中';
    if (s == 'completed') return type == 'delivery' ? '已送达' : '已完成';
    switch (s) {
      case 'submitted': return '已提交';
      case 'accepted': return '前台已接单';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted': return const Color(0xFF1677FF);
      case 'accepted': return const Color(0xFF52C41A);
      case 'processing': return const Color(0xFFFAAD14);
      case 'completed': return const Color(0xFF52C41A);
      default: return Colors.grey;
    }
  }

  void _showCreateDialog() {
    String selectedType = 'delivery';
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新建服务请求'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'delivery', label: Text('📦 送物'), icon: Icon(Icons.delivery_dining)),
                  ButtonSegment(value: 'repair', label: Text('🔧 报修'), icon: Icon(Icons.build)),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) => setDialogState(() => selectedType = v.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '需求描述',
                  hintText: '例如：送两双拖鞋 / 马桶堵了',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final content = contentController.text.trim();
                if (content.isEmpty) return;
                context.read<WorkOrderBloc>().add(WorkOrderCreated(type: selectedType, content: content));
                Navigator.pop(ctx);
              },
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthBloc>().state.status == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('📋 服务追踪'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
      floatingActionButton: isLoggedIn ? FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('新建服务'),
        backgroundColor: const Color(0xFF1677FF),
        foregroundColor: Colors.white,
      ) : null,
      body: isLoggedIn ? _buildOrderList() : const AuthPrompt.overlay(
        icon: '🔧',
        title: '服务工单',
        description: '登录后查看工单进度\n提交维修 · 保洁 · 送物等服务',
      ),
    );
  }

  Widget _buildOrderList() {
    return BlocBuilder<WorkOrderBloc, WorkOrderState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.read<WorkOrderBloc>().add(WorkOrdersFetched()), child: const Text('重试')),
          ]));
        }
        if (state.orders.isEmpty) {
          return const Center(child: Text('暂无服务请求', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.orders.length,
          itemBuilder: (context, idx) {
            final wo = state.orders[idx];
            final color = _statusColor(wo.status);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4, right: 12),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_statusLabel(wo.status, wo.type), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text('${wo.type == 'delivery' ? '📦' : '🔧'} ${wo.content}'),
                    if (wo.assignedResource != null) Text('指派：${wo.assignedResource}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(wo.createdAt.toString().substring(0, 16), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ])),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
