import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../services/onepay_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isDelivery = true;
  bool _placing = false;
  String _paymentMethod = 'cash'; // 'cash' or 'card'
  late OnepayService _onepayService;

  @override
  void initState() {
    super.initState();
    _onepayService = OnepayService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if logged in
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      await Navigator.pushNamed(context, AppRoutes.phoneEntry);
      if (!mounted) return;
      final userAfterLogin = ref.read(authStateProvider).valueOrNull;
      if (userAfterLogin == null) return;
    }

    setState(() => _placing = true);

    try {
      final cartItems = ref.read(cartProvider);
      final subtotal = ref.read(cartSubtotalProvider);
      final deliveryFee = _isDelivery ? AppConstants.deliveryFee : 0.0;
      final total = subtotal + deliveryFee;
      final firestoreService = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(authStateProvider).valueOrNull;

      final orderNumber = await firestoreService.getNextOrderNumber();

      // Build order object
      final order = OrderModel(
        id: '',
        orderNumber: orderNumber,
        customerId: currentUser?.uid ?? '',
        customerName: _nameController.text.trim(),
        customerPhone: '${AppConstants.countryCode}${_phoneController.text.trim()}',
        type: _isDelivery ? 'delivery' : 'pickup',
        address: _isDelivery ? _addressController.text.trim() : '',
        status: AppConstants.statusReceived,
        note: _noteController.text.trim(),
        items: cartItems
            .map((item) => OrderItem(
                  itemId: item.itemId,
                  name: item.name,
                  size: item.size,
                  quantity: item.quantity,
                  price: item.price,
                ))
            .toList(),
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentMethod == 'cash' ? 'pending' : 'pending',
      );

      // If card payment, process with OnePay
      if (_paymentMethod == 'card') {
        await _processCardPayment(order, firestoreService);
      } else {
        // Cash payment — save order directly
        await _saveOrderToFirestore(order, firestoreService, orderNumber);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processCardPayment(
    OrderModel order,
    dynamic firestoreService,
  ) async {
    // Initialize OnePay with customer details
    _onepayService.initialize(
      firstName: _nameController.text.trim().split(' ').first,
      lastName: _nameController.text.trim().split(' ').last,
      phoneNumber: _phoneController.text.trim(),
    );

    // For now, use test card token. In production, customer would select saved card
    const testCardToken = 'test_card_token_001';

    // Create a Completer to wait for payment result
    final completer = Completer<bool>();

    // Process payment
    _onepayService.makePayment(
      amount: order.total,
      customerCardToken: testCardToken,
      onResult: (success, message, transactionId) async {
        if (!mounted) {
          completer.completeError('Widget not mounted');
          return;
        }

        if (success) {
          // Payment successful — update order with payment info
          final updatedOrder = OrderModel(
            id: order.id,
            orderNumber: order.orderNumber,
            customerId: order.customerId,
            customerName: order.customerName,
            customerPhone: order.customerPhone,
            type: order.type,
            address: order.address,
            status: order.status,
            note: order.note,
            items: order.items,
            subtotal: order.subtotal,
            deliveryFee: order.deliveryFee,
            total: order.total,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
            paymentMethod: 'card',
            paymentStatus: 'paid',
            paymentTransactionId: transactionId,
          );

          try {
            await _saveOrderToFirestore(updatedOrder, firestoreService, order.orderNumber);
            completer.complete(true);
          } catch (e) {
            completer.completeError(e);
          }
        } else {
          // Payment failed
          if (mounted) {
            setState(() => _placing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: $message'),
                backgroundColor: Colors.red,
              ),
            );
          }
          completer.complete(false);
        }
      },
    );

    // Wait for payment to complete
    try {
      await completer.future;
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveOrderToFirestore(
    OrderModel order,
    dynamic firestoreService,
    int orderNumber,
  ) async {
    final orderId = await firestoreService.createOrder(order);
    ref.read(cartProvider.notifier).clearCart();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.orderConfirmation,
        (route) => false,
        arguments: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'total': order.total,
          'type': order.type,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = _isDelivery ? AppConstants.deliveryFee : 0.0;
    final total = subtotal + deliveryFee;
    final shopSettings = ref.watch(shopSettingsProvider);
    final isShopOpen = shopSettings.valueOrNull?.isOpenRightNow ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery / Pickup toggle
              Text('Order Type',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      label: 'Delivery',
                      icon: Icons.delivery_dining,
                      selected: _isDelivery,
                      onTap: () => setState(() => _isDelivery = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Pickup',
                      icon: Icons.store,
                      selected: !_isDelivery,
                      onTap: () => setState(() => _isDelivery = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Customer info
              Text('Your Details',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  prefixText: '${AppConstants.countryCode} ',
                ),
                validator: (v) => v == null || v.trim().length < 9
                    ? 'Enter a valid phone number'
                    : null,
              ),

              if (_isDelivery) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => _isDelivery && (v == null || v.trim().isEmpty)
                      ? 'Enter your delivery address'
                      : null,
                ),
              ],

              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Order Note (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),

              const SizedBox(height: 24),

              // Payment method
              Text('Payment Method',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      label: 'Cash',
                      icon: Icons.attach_money,
                      selected: _paymentMethod == 'cash',
                      onTap: () => setState(() => _paymentMethod = 'cash'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Card',
                      icon: Icons.credit_card,
                      selected: _paymentMethod == 'card',
                      onTap: () => setState(() => _paymentMethod = 'card'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Order summary
              Text('Order Summary',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...cartItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${item.quantity}x',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.name} (${item.size[0].toUpperCase()})',
                                  ),
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
                      _SummaryRow(label: 'Subtotal', amount: subtotal),
                      _SummaryRow(
                        label: 'Delivery Fee',
                        amount: deliveryFee,
                      ),
                      const Divider(),
                      _SummaryRow(label: 'Total', amount: total, bold: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Place order
              Column(
                children: [
                  if (!isShopOpen)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.store_outlined,
                              color: AppColors.warning, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Shop is currently closed',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_placing || !isShopOpen) ? null : _placeOrder,
                      child: _placing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Place Order · ${AppConstants.currencySymbol} ${total.toStringAsFixed(0)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textGrey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.white : AppColors.textGrey,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _SummaryRow({
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
