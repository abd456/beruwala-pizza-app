import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/shop_settings_model.dart';
import '../utils/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Menu Items ───

  Stream<List<MenuItemModel>> getMenuItems() {
    return _firestore
        .collection(AppConstants.menuItemsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<MenuItemModel>> getAvailableMenuItems() {
    return _firestore
        .collection(AppConstants.menuItemsCollection)
        .where('available', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<MenuItemModel>> getMenuItemsByCategory(String category) {
    return _firestore
        .collection(AppConstants.menuItemsCollection)
        .where('available', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  // ─── Orders ───

  Future<String> createOrder(OrderModel order) async {
    final doc = await _firestore
        .collection(AppConstants.ordersCollection)
        .add(order.toFirestore());
    return doc.id;
  }

  Stream<List<OrderModel>> getOrdersByCustomer(String customerId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Stream<OrderModel?> getOrder(String orderId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }

  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // ─── Menu Management (Admin) ───

  Future<void> addMenuItem(MenuItemModel item) async {
    await _firestore
        .collection(AppConstants.menuItemsCollection)
        .add(item.toFirestore());
  }

  Future<void> updateMenuItem(String itemId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.menuItemsCollection)
        .doc(itemId)
        .update(data);
  }

  Future<void> toggleMenuItemAvailability(String itemId, bool available) async {
    await _firestore
        .collection(AppConstants.menuItemsCollection)
        .doc(itemId)
        .update({'available': available});
  }

  Future<void> deleteMenuItem(String itemId) async {
    await _firestore
        .collection(AppConstants.menuItemsCollection)
        .doc(itemId)
        .delete();
  }

  // ─── Order Number ───

  Future<int> getNextOrderNumber() async {
    final counterRef = _firestore
        .collection(AppConstants.settingsCollection)
        .doc('orderCounter');

    return _firestore.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      final next = snap.exists ? ((snap.data()?['count'] as int? ?? 1000) + 1) : 1001;
      tx.set(counterRef, {'count': next}, SetOptions(merge: true));
      return next;
    });
  }

  // ─── Shop Settings ───

  Stream<ShopSettingsModel?> getShopSettings() {
    return _firestore
        .collection(AppConstants.settingsCollection)
        .doc(AppConstants.shopSettingsDocument)
        .snapshots()
        .map((doc) => doc.exists ? ShopSettingsModel.fromFirestore(doc) : null);
  }

  Future<void> updateShopSettings(Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.settingsCollection)
        .doc(AppConstants.shopSettingsDocument)
        .set(data, SetOptions(merge: true));
  }
}
