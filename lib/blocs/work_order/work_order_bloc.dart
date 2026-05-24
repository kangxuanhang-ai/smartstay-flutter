import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import 'work_order_event.dart';
import 'work_order_state.dart';

class WorkOrderBloc extends Bloc<Object, WorkOrderState> {
  WorkOrderBloc() : super(const WorkOrderState()) {
    on<WorkOrdersFetched>(_onFetched);
    on<WorkOrderRefreshRequested>(_onRefresh);
  }

  final _api = ApiClient();

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
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _onRefresh(WorkOrderRefreshRequested event, Emitter<WorkOrderState> emit) async {
    add(WorkOrdersFetched());
  }
}
