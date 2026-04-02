import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import 'menu_provider.dart';

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllOrders();
});

final selectedOrderStatusFilter = StateProvider<String?>((ref) => null);

final filteredOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final statusFilter = ref.watch(selectedOrderStatusFilter);
  final orders = ref.watch(allOrdersProvider);

  return orders.whenData((list) {
    if (statusFilter == null) return list;
    return list.where((o) => o.status == statusFilter).toList();
  });
});

// Customer's own orders — keyed by their Firebase uid
final customerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((
  ref,
  customerId,
) {
  return ref.watch(firestoreServiceProvider).getOrdersByCustomer(customerId);
});
