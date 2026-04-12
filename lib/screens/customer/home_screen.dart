import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/menu_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../widgets/menu_item_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(searchedMenuItemsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final shopSettings = ref.watch(shopSettingsProvider);
    final activeCategories = ref.watch(activeCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: const [],
      ),
      body: Column(
        children: [
          // Closed banner — only shown when the shop is confirmed closed
          if (shopSettings.valueOrNull != null &&
              !shopSettings.valueOrNull!.isOpenRightNow)
            _ClosedBanner(nextOpen: shopSettings.valueOrNull!.nextOpenDescription),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) =>
                  ref.read(menuSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: selectedCategory == null,
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = null,
                ),
                ...activeCategories.valueOrNull?.map((cat) => _CategoryChip(
                      label: cat.name,
                      selected: selectedCategory == cat.name,
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = cat.name,
                    )) ?? [],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Menu grid
          Expanded(
            child: menuItems.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items found'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MenuItemCard(
                      item: item,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.itemDetail,
                        arguments: item,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  final String? nextOpen;

  const _ClosedBanner({this.nextOpen});

  @override
  Widget build(BuildContext context) {
    final subtitle = nextOpen != null ? ' · Opens $nextOpen' : '';
    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: AppColors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "We're currently closed$subtitle",
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(
          color: selected
              ? AppColors.white
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
