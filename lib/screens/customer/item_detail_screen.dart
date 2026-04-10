import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/menu_item_model.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  String? _selectedVariation;
  int _quantity = 1;
  int _currentImageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as MenuItemModel;
    final variations = item.prices.entries.toList();
    final images = item.imageUrls;

    // Auto-select first variation on first build
    if (_selectedVariation == null && variations.isNotEmpty) {
      _selectedVariation = variations.first.key;
    }

    final currentPrice = item.getPrice(_selectedVariation ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                      color: AppColors.background,
                      child: const Icon(Icons.local_pizza,
                          size: 80, color: AppColors.primary),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemBuilder: (context, i) => CachedNetworkImage(
                            imageUrl: images[i],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.background,
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, err) => Container(
                              color: AppColors.background,
                              child: const Icon(Icons.local_pizza,
                                  size: 80, color: AppColors.primary),
                            ),
                          ),
                        ),
                        // Dot indicators (only when >1 image)
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (i) {
                                final active = i == _currentImageIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: active ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.white
                                        : AppColors.white
                                            .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(item.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),

                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (item.description.isNotEmpty) ...[
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textGrey,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Variation selector
                  if (variations.isNotEmpty) ...[
                    Text(
                      variations.length == 1 ? 'Variation' : 'Choose Variation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: variations.map((entry) {
                        final selected = _selectedVariation == entry.key;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedVariation = entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textGrey
                                        .withValues(alpha: 0.3),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                                if ((item.variationDetails[entry.key] ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.variationDetails[entry.key]!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected
                                          ? AppColors.white
                                              .withValues(alpha: 0.8)
                                          : AppColors.textGrey,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '${AppConstants.currencySymbol} ${entry.value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quantity selector
                  Text('Quantity',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        onTap: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

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
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${AppConstants.currencySymbol} ${(currentPrice * _quantity).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedVariation == null
                      ? null
                      : () {
                          ref.read(cartProvider.notifier).addItem(
                                CartItemModel(
                                  itemId: item.id,
                                  name: item.name,
                                  imageUrl: item.imageUrl,
                                  size: _selectedVariation!,
                                  quantity: _quantity,
                                  price: currentPrice,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary
              : AppColors.textGrey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppColors.white : AppColors.textGrey,
        ),
      ),
    );
  }
}
