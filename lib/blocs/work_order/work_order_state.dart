class WOrder {
  final String id;
  final String type;
  final String content;
  final String status;
  final String? assignedResource;
  final DateTime createdAt;

  const WOrder({
    required this.id,
    required this.type,
    required this.content,
    required this.status,
    this.assignedResource,
    required this.createdAt,
  });
}

class WorkOrderState {
  final List<WOrder> orders;
  final bool loading;
  final String? error;

  const WorkOrderState({this.orders = const [], this.loading = false, this.error});

  WorkOrderState copyWith({List<WOrder>? orders, bool? loading, String? error}) {
    return WorkOrderState(
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
