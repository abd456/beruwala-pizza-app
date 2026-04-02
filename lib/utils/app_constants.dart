class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Beruwala Pizza';
  static const String tagline = 'Fresh. Hot. Delivered.';

  // Currency
  static const String currency = 'LKR';
  static const String currencySymbol = 'Rs.';

  // Phone
  static const String countryCode = '+94';

  // Delivery
  static const double deliveryFee = 300.0; // LKR - confirm with client

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String menuItemsCollection = 'menuItems';
  static const String ordersCollection = 'orders';
  static const String settingsCollection = 'settings';
  static const String shopSettingsDocument = 'shopSettings';

  // Roles
  static const String customerRole = 'customer';
  static const String adminRole = 'admin';

  // Order Statuses
  static const String statusReceived = 'received';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusDelivered = 'delivered';

  // Categories
  static const List<String> menuCategories = [
    'Pizza',
    'Sides',
    'Drinks',
    'Desserts',
  ];

  // Sizes
  static const String sizeSmall = 'small';
  static const String sizeMedium = 'medium';
  static const String sizeLarge = 'large';

  // Hidden Staff Access
  static const int staffAccessTapCount = 5;
}
