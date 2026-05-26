import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import '../../core/ws_service.dart';
import 'work_order_event.dart';
import 'work_order_state.dart';

class WorkOrderBloc extends Bloc<WorkOrderEvent, WorkOrderState> {
  final _api = ApiClient();
  final _ws = WsService();
  StreamSubscription? _wsSub;

  WorkOrderBloc() : super(const WorkOrderState()) {
    on<WorkOrdersFetched>(_onFetched);
    on<WorkOrderRefreshRequested>(_onRefresh);
    on<WorkOrderCreated>(_onCreated);

    _wsSub = _ws.events.listen((msg) {
      if (msg['event'] == 'work_order.status_change') {
        add(WorkOrdersFetched());
      }
    });
  }

  Future<void> _onFetched(WorkOrdersFetched event, Emitter<WorkOrderState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final resp = await _api.get('/api/work-orders/my-orders');
      final list = resp.data as List<dynamic>;
      final orders = list.map((o) => WOrder(
        id: o['id'] ?? '',
        type: o['type'] ?? '',
        content: o['content'] ?? '',
        status: o['status'] ?? '',
        assignedResource: o['assigned_resource'],
        createdAt: DateTime.tryParse(o['created_at'] ?? '') ?? DateTime.now(),
      )).toList();
      emit(WorkOrderState(orders: orders));
    } catch (_) {
      emit(state.copyWith(loading: false, error: '加载工单数据失败'));
    }
  }

  Future<void> _onRefresh(WorkOrderRefreshRequested event, Emitter<WorkOrderState> emit) async {
    add(WorkOrdersFetched());
  }

  Future<void> _onCreated(WorkOrderCreated event, Emitter<WorkOrderState> emit) async {
    try {
      // Get current room_id from my-room endpoint
      final roomResp = await _api.get('/api/rooms/my-room');
      final roomId = roomResp.data['id'] as String?;

      await _api.post('/api/work-orders/', data: {
        'room_id': roomId ?? '',
        'type': event.type,
        'content': event.content,
      });
      add(WorkOrdersFetched());
    } catch (_) {
      emit(state.copyWith(error: '创建工单失败'));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
