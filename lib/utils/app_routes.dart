import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/item_detail_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/phone_entry_screen.dart';
import '../screens/customer/otp_screen.dart';
import '../screens/customer/order_confirmation_screen.dart';
import '../screens/customer/order_tracking_screen.dart';
import '../screens/admin/staff_login_screen.dart';
import '../screens/admin/orders_dashboard_screen.dart';
import '../screens/admin/order_detail_screen.dart';
import '../screens/admin/status_update_screen.dart';
import '../screens/admin/menu_management_screen.dart';
import '../screens/admin/add_item_screen.dart';
import '../screens/admin/edit_item_screen.dart';

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
  static const String statusUpdate = '/status-update';
  static const String menuManagement = '/menu-management';
  static const String addItem = '/add-item';
  static const String editItem = '/edit-item';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        home: (_) => const HomeScreen(),
        cart: (_) => const CartScreen(),
        checkout: (_) => const CheckoutScreen(),
        phoneEntry: (_) => const PhoneEntryScreen(),
        otp: (_) => const OtpScreen(),
        orderConfirmation: (_) => const OrderConfirmationScreen(),
        staffLogin: (_) => const StaffLoginScreen(),
        ordersDashboard: (_) => const OrdersDashboardScreen(),
        menuManagement: (_) => const MenuManagementScreen(),
        addItem: (_) => const AddItemScreen(),
      };
}
