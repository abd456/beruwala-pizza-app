import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../widgets/status_badge.dart';

class OrdersDashboardScreen extends ConsumerWidget {
  const OrdersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(filteredOrdersProvider);
    final selectedStatus = ref.watch(selectedOrderStatusFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Menu Management',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.menuManagement),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.splash,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter tabs
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: selectedStatus == null,
                  onTap: () => ref
                      .read(selectedOrderStatusFilter.notifier)
                      .state = null,
                ),
                _FilterChip(
                  label: 'New',
                  selected: selectedStatus == AppConstants.statusReceived,
                  color: AppColors.info,
                  onTap: () => ref
                      .read(selectedOrderStatusFilter.notifier)
                      .state = AppConstants.statusReceived,
                ),
                _FilterChip(
                  label: 'Preparing',
                  selected: selectedStatus == AppConstants.statusPreparing,
                  color: AppColors.warning,
                  onTap: () => ref
                      .read(selectedOrderStatusFilter.notifier)
                      .state = AppConstants.statusPreparing,
                ),
                _FilterChip(
                  label: 'Ready',
                  selected: selectedStatus == AppConstants.statusReady,
                  color: AppColors.accent,
                  onTap: () => ref
                      .read(selectedOrderStatusFilter.notifier)
                      .state = AppConstants.statusReady,
                ),
                _FilterChip(
                  label: 'Delivered',
                  selected: selectedStatus == AppConstants.statusDelivered,
                  color: AppColors.success,
                  onTap: () => ref
                      .read(selectedOrderStatusFilter.notifier)
                      .state = AppConstants.statusDelivered,
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: orders.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final order = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.orderDetail,
                          arguments: order,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${order.orderNumber}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const Spacer(),
                                  StatusBadge(status: order.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 16, color: AppColors.textGrey),
                                  const SizedBox(width: 4),
                                  Text(order.customerName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  const SizedBox(width: 16),
                                  Icon(
                                    order.isDelivery
                                        ? Icons.delivery_dining
                                        : Icons.store,
                                    size: 16,
                                    color: AppColors.textGrey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.isDelivery ? 'Delivery' : 'Pickup',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${AppConstants.currencySymbol} ${order.total.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, h:mm a')
                                    .format(order.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: chipColor,
        backgroundColor: Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(
          color: selected ? AppColors.white : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        checkmarkColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
