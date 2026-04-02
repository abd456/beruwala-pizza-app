import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/customer/customer_shell.dart';
import '../screens/customer/item_detail_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/phone_entry_screen.dart';
import '../screens/customer/otp_screen.dart';
import '../screens/customer/order_confirmation_screen.dart';
import '../screens/customer/order_tracking_screen.dart';
import '../screens/admin/staff_login_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/order_detail_screen.dart';
import '../screens/admin/add_item_screen.dart';
import '../screens/admin/edit_item_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/customer/my_orders_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String home = '/home';
  static const String itemDetail = '/item-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String phoneEntry = '/phone-entry';
  static const String otp = '/otp';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderTracking = '/order-tracking';
  static const String staffLogin = '/staff-login';
  static const String ordersDashboard = '/orders-dashboard';
  static const String orderDetail = '/order-detail';
  static const String menuManagement = '/menu-management';
  static const String addItem = '/add-item';
  static const String editItem = '/edit-item';
  static const String myOrders = '/my-orders';
  static const String shopSettings = '/shop-settings';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    home: (_) => const CustomerShell(),
    itemDetail: (_) => const ItemDetailScreen(),
    cart: (_) => const CustomerShell(),
    checkout: (_) => const CheckoutScreen(),
    phoneEntry: (_) => const PhoneEntryScreen(),
    otp: (_) => const OtpScreen(),
    orderConfirmation: (_) => const OrderConfirmationScreen(),
    orderTracking: (_) => const OrderTrackingScreen(),
    staffLogin: (_) => const StaffLoginScreen(),
    ordersDashboard: (_) => const AdminShell(),
    orderDetail: (_) => const OrderDetailScreen(),
    menuManagement: (_) => const AdminShell(),
    addItem: (_) => const AddItemScreen(),
    editItem: (_) => const EditItemScreen(),
    myOrders: (_) => const MyOrdersScreen(),
    shopSettings: (_) => const SettingsScreen(),
  };
}
