import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../utils/app_constants.dart';

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  void addItem(CartItemModel item) {
    // Check if same item with same size already in cart
    final existingIndex = state.indexWhere(
      (i) => i.itemId == item.itemId && i.size == item.size,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final existing = state[existingIndex];
      final updated = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(int index) {
    state = [...state]..removeAt(index);
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final updated = state[index].copyWith(quantity: quantity);
    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.totalPrice);
});

final cartDeliveryFeeProvider = Provider<double>((ref) {
  return AppConstants.deliveryFee;
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});
