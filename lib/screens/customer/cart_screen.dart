import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: AppColors.textGrey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textGrey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse the menu and add items',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                ),
                child: const Text('Browse Menu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return Dismissible(
            key: ValueKey('${item.itemId}_${item.size}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              ref.read(cartProvider.notifier).removeItem(index);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: AppColors.white),
            ),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: item.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const Icon(
                                  Icons.local_pizza,
                                  color: AppColors.primary,
                                ),
                              )
                            : Container(
                                color: AppColors.background,
                                child: const Icon(
                                  Icons.local_pizza,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Size: ${item.size[0].toUpperCase()}  ·  ${AppConstants.currencySymbol} ${item.price.toStringAsFixed(0)} each',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _CartQuantityButton(
                                icon: Icons.remove,
                                onTap: () async {
                                  if (item.quantity == 1) {
                                    final remove = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remove item?'),
                                        content: Text(
                                            'Remove ${item.name} from your cart?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Keep'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                  color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (remove == true) {
                                      ref
                                          .read(cartProvider.notifier)
                                          .removeItem(index);
                                    }
                                  } else {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                            index, item.quantity - 1);
                                  }
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _CartQuantityButton(
                                icon: Icons.add,
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(index, item.quantity + 1),
                              ),
                              const Spacer(),
                              Text(
                                '${AppConstants.currencySymbol} ${item.totalPrice.toStringAsFixed(0)}',
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      // Bottom bar: totals + checkout
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PriceRow(label: 'Subtotal', amount: subtotal),
              const SizedBox(height: 6),
              _PriceRow(
                label: 'Delivery Fee',
                amount: AppConstants.deliveryFee,
              ),
              const Divider(height: 20),
              _PriceRow(
                label: 'Total',
                amount: subtotal + AppConstants.deliveryFee,
                bold: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.checkout),
                  child: const Text('Proceed to Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartQuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CartQuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)
              : Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          '${AppConstants.currencySymbol} ${amount.toStringAsFixed(0)}',
          style: bold
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
