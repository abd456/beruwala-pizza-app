import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

// Per-order stream provider keyed by orderId
final _orderStreamProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(firestoreServiceProvider).getOrder(orderId);
});

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = ModalRoute.of(context)!.settings.arguments as String;
    final orderAsync = ref.watch(_orderStreamProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }
          return _OrderTrackingBody(order: order);
        },
      ),
    );
  }
}

class _OrderTrackingBody extends StatelessWidget {
  final OrderModel order;

  const _OrderTrackingBody({required this.order});

  static const _statuses = [
    AppConstants.statusReceived,
    AppConstants.statusPreparing,
    AppConstants.statusReady,
    AppConstants.statusDelivered,
  ];

  static const _statusLabels = {
    AppConstants.statusReceived: 'Order Received',
    AppConstants.statusPreparing: 'Preparing',
    AppConstants.statusReady: 'Ready',
    AppConstants.statusDelivered: 'Delivered',
  };

  static const _statusIcons = {
    AppConstants.statusReceived: Icons.receipt_long,
    AppConstants.statusPreparing: Icons.local_fire_department,
    AppConstants.statusReady: Icons.check_circle,
    AppConstants.statusDelivered: Icons.delivery_dining,
  };

  static const _statusDescriptions = {
    AppConstants.statusReceived: 'We\'ve received your order!',
    AppConstants.statusPreparing: 'Our chefs are making your pizza.',
    AppConstants.statusReady: 'Your order is ready!',
    AppConstants.statusDelivered: 'Enjoy your meal!',
  };

  DateTime? _timestampForStep(String status) {
    if (status == AppConstants.statusReceived) {
      return order.createdAt;
    }
    if (status == AppConstants.statusDelivered &&
        order.status == AppConstants.statusDelivered) {
      return order.updatedAt;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _statuses.indexOf(order.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    _StatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      order.isDelivery
                          ? Icons.delivery_dining
                          : Icons.storefront,
                      size: 16,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.isDelivery ? 'Delivery' : 'Pickup',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textGrey,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${AppConstants.currencySymbol} ${order.total.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 16),

          // Stepper
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_statuses.length, (index) {
                final status = _statuses[index];
                final isDone = index <= currentIndex;
                final isCurrent = index == currentIndex;
                final isLast = index == _statuses.length - 1;

                return _StepRow(
                  icon: _statusIcons[status]!,
                  label: _statusLabels[status]!,
                  description: _statusDescriptions[status]!,
                  isDone: isDone,
                  isCurrent: isCurrent,
                  isLast: isLast,
                  timestamp: _timestampForStep(status),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Order summary
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}×',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.name} (${item.size[0].toUpperCase()})',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${AppConstants.currencySymbol} ${item.totalPrice.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                _SummaryRow(
                    label: 'Subtotal', value: order.subtotal),
                const SizedBox(height: 4),
                _SummaryRow(
                    label: 'Delivery Fee', value: order.deliveryFee),
                const Divider(height: 16),
                _SummaryRow(
                    label: 'Total', value: order.total, bold: true),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final DateTime? timestamp;

  const _StepRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.success : AppColors.textGrey.withValues(alpha: 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + vertical line
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone && !isCurrent
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.background,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Label + description
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDone ? AppColors.textDark : AppColors.textGrey,
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                        ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textGrey,
                          ),
                    ),
                  ],
                  if (timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('h:mm a · MMM d').format(timestamp!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isDone)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(Icons.check, size: 18, color: AppColors.success),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      AppConstants.statusReceived => (AppColors.info, AppColors.info.withValues(alpha: 0.1)),
      AppConstants.statusPreparing => (AppColors.warning, AppColors.warning.withValues(alpha: 0.1)),
      AppConstants.statusReady => (AppColors.success, AppColors.success.withValues(alpha: 0.1)),
      AppConstants.statusDelivered => (AppColors.textGrey, AppColors.background),
      _ => (AppColors.textGrey, AppColors.background),
    };

    final label = switch (status) {
      AppConstants.statusReceived => 'Received',
      AppConstants.statusPreparing => 'Preparing',
      AppConstants.statusReady => 'Ready',
      AppConstants.statusDelivered => 'Delivered',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)
              : Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textGrey),
        ),
        Text(
          '${AppConstants.currencySymbol} ${value.toStringAsFixed(0)}',
          style: bold
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  )
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
