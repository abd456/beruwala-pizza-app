import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

/// Handles FCM token management and foreground notification display.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Request permission + store token. Call once after login.
  Future<void> init(String userId) async {
    // Request permission (iOS requires this; Android auto-grants)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and store FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(userId, newToken);
    });
  }

  Future<void> _saveToken(String userId, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  /// Remove token on logout so the user stops receiving notifications.
  Future<void> clearToken(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': FieldValue.delete()});
  }

  /// Set up foreground message handler — shows a snackbar.
  void setupForegroundListener(GlobalKey<NavigatorState> navigatorKey) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}
