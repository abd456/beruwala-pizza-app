import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/shop_settings_model.dart';
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

final shopSettingsProvider = StreamProvider<ShopSettingsModel?>((ref) {
  return ref.watch(firestoreServiceProvider).getShopSettings();
});

// ─── Categories ───

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getCategories();
});

// All menu items (available + unavailable) — used for admin item count
final allMenuItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getMenuItems();
});

// Categories that have at least one AVAILABLE item — drives home screen chips
final activeCategoriesProvider = Provider<AsyncValue<List<CategoryModel>>>((ref) {
  final categories = ref.watch(categoriesProvider);
  final items = ref.watch(menuItemsProvider); // available items only

  return categories.whenData((cats) {
    return items.whenData((menuItems) {
      final usedNames = menuItems.map((i) => i.category).toSet();
      return cats.where((c) => usedNames.contains(c.name)).toList();
    }).valueOrNull ?? [];
  });
});
