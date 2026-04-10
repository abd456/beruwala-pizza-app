import 'package:flutter/material.dart';
import 'package:ipg_flutter/ipg_flutter.dart';
import '../utils/app_secrets.dart';

class OnepayService {
  late Ipg _ipg;

  /// Initialize OnePay with customer details
  void initialize({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String email = 'customer@beruwalapizza.com',
  }) {
    _ipg = Ipg.init(
      appToken: AppSecrets.onepayAppToken,
      appId: AppSecrets.onepayAppId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
    );
  }

  /// Make customer payment (as per official OnePay docs)
  /// amount: String (e.g., "5000.00")
  /// currencyCode: String (e.g., "LKR")
  /// customerCardToken: String (customer's saved card token)
  void makePayment({
    required double amount,
    required String customerCardToken,
    required Function(bool success, String message, String? transactionId)
        onResult,
  }) {
    final amountStr = amount.toStringAsFixed(2);

    debugPrint('💳 Processing payment: $amountStr LKR');

    // Make customer payment
    _ipg.makeCustomerPayment(amountStr, 'LKR', customerCardToken);

    // Listen to payment status
    _ipg.customerPaymentEventCallback = (status, errorMessage) {
      debugPrint('📲 Payment callback - Status: $status, Error: $errorMessage');

      // status is a boolean from ipg_flutter library
      final isSuccess = status == true;

      if (isSuccess) {
        debugPrint('✅ Payment successful');
        final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
        onResult(true, 'Payment successful', transactionId);
      } else {
        debugPrint('❌ Payment failed: $errorMessage');
        onResult(false, errorMessage ?? 'Payment failed', null);
      }
    };
  }

  /// Add a new card (as per official OnePay docs)
  void addCard(BuildContext context) {
    _ipg.addNewCard(context);

    // Callback when card add flow completes
    _ipg.addCardEventCallback = (status, errorMessage) {
      debugPrint('Card add result: $status - $errorMessage');
      if (status == true) {
        debugPrint('✅ Card added successfully');
      } else {
        debugPrint('❌ Card add failed: $errorMessage');
      }
    };
  }

  /// Retrieve customer's saved cards (as per official OnePay docs)
  void getCustomers() {
    _ipg.getCustomers();

    // Callback when customers are retrieved
    _ipg.getCustomersEventCallback = (customerList, errorMessage) {
      if (customerList != null && customerList.isNotEmpty) {
        debugPrint('✅ Found ${customerList.length} saved card(s)');
      } else {
        debugPrint('❌ No saved cards found: $errorMessage');
      }
    };
  }
}
