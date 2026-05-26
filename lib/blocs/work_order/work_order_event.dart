sealed class WorkOrderEvent {}

class WorkOrdersFetched extends WorkOrderEvent {}

class WorkOrderRefreshRequested extends WorkOrderEvent {}

class WorkOrderCreated extends WorkOrderEvent {
  final String type;
  final String content;
  WorkOrderCreated({required this.type, required this.content});
}
