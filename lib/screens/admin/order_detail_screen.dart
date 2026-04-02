import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _updating = false;

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    setState(() => _updating = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_statusLabel(newStatus)}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusReceived:
        return 'Received';
      case AppConstants.statusPreparing:
        return 'Preparing';
      case AppConstants.statusReady:
        return 'Ready';
      case AppConstants.statusDelivered:
        return 'Delivered';
      default:
        return status;
    }
  }

  String? _nextStatus(String current) {
    switch (current) {
      case AppConstants.statusReceived:
        return AppConstants.statusPreparing;
      case AppConstants.statusPreparing:
        return AppConstants.statusReady;
      case AppConstants.statusReady:
        return AppConstants.statusDelivered;
      default:
        return null;
    }
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
    final next = _nextStatus(order.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Order #${order.orderNumber}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Status: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    StatusBadge(status: order.status),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, h:mm a').format(order.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customer info
            Text('Customer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                        icon: Icons.person_outline, text: order.customerName),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 18, color: AppColors.textGrey),
                        const SizedBox(width: 8),
                        Text(order.customerPhone),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.call,
                              color: AppColors.success, size: 20),
                          onPressed: () => _callCustomer(order.customerPhone),
                        ),
                      ],
                    ),
                    if (order.isDelivery) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: order.address),
                    ],
                    _InfoRow(
                      icon: order.isDelivery
                          ? Icons.delivery_dining
                          : Icons.store,
                      text: order.isDelivery ? 'Delivery' : 'Pickup',
                    ),
                    if (order.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.note_outlined, text: order.note),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items
            Text('Items', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text('${item.quantity}x',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    '${item.name} (${item.size[0].toUpperCase()})'),
                              ),
                              Text(
                                '${AppConstants.currencySymbol} ${item.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                    _PriceRow(label: 'Subtotal', amount: order.subtotal),
                    _PriceRow(label: 'Delivery Fee', amount: order.deliveryFee),
                    const Divider(),
                    _PriceRow(label: 'Total', amount: order.total, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Update status button
            if (next != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updating
                      ? null
                      : () => _updateStatus(order, next),
                  icon: _updating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text('Mark as ${_statusLabel(next)}'),
                ),
              ),

            if (next == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Order completed',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold
                  ? const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)
                  : null),
          Text(
            '${AppConstants.currencySymbol} ${amount.toStringAsFixed(0)}',
            style: bold
                ? const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary)
                : null,
          ),
        ],
      ),
    );
  }
}
