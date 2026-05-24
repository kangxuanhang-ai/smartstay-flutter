import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/work_order/work_order_bloc.dart';
import '../../blocs/work_order/work_order_event.dart';
import '../../blocs/work_order/work_order_state.dart';

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

  String _statusLabel(String s) {
    switch (s) {
      case 'submitted': return '已提交';
      case 'accepted': return '前台已接单';
      case 'processing': return '保洁/维修中';
      case 'completed': return '已送达/完成';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📋 服务追踪'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
      body: BlocBuilder<WorkOrderBloc, WorkOrderState>(
        builder: (context, state) {
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4, right: 12),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_statusLabel(wo.status), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                            const SizedBox(height: 4),
                            Text('${wo.type == 'delivery' ? '📦' : '🔧'} ${wo.content}'),
                            if (wo.assignedResource != null)
                              Text('指派：${wo.assignedResource}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(wo.createdAt.toString().substring(0, 16), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
