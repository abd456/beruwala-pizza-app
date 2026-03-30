import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final menuItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAvailableMenuItems();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredMenuItemsProvider = Provider<AsyncValue<List<MenuItemModel>>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final menuItems = ref.watch(menuItemsProvider);

  return menuItems.whenData((items) {
    if (category == null) return items;
    return items.where((item) => item.category == category).toList();
  });
});

final menuSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedMenuItemsProvider = Provider<AsyncValue<List<MenuItemModel>>>((ref) {
  final query = ref.watch(menuSearchQueryProvider).toLowerCase();
  final items = ref.watch(filteredMenuItemsProvider);

  return items.whenData((list) {
    if (query.isEmpty) return list;
    return list
        .where((item) =>
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query))
        .toList();
  });
});
