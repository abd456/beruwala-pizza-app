import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/menu_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

// Admin needs ALL items (including unavailable)
final allMenuItemsProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).getMenuItems();
});

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(allMenuItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addItem),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: menuItems.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 80,
                      color: AppColors.textGrey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No menu items yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textGrey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first item'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
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
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.local_pizza,
                                  color: AppColors.primary),
                            ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.category}  ·  ${AppConstants.currencySymbol} ${(item.prices.values.isNotEmpty ? item.prices.values.first : 0.0).toStringAsFixed(0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.available,
                        activeThumbColor: AppColors.success,
                        onChanged: (v) {
                          ref
                              .read(firestoreServiceProvider)
                              .toggleMenuItemAvailability(item.id, v);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.editItem,
                          arguments: item,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
