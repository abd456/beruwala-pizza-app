import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';
import 'utils/app_routes.dart';

/// Top-level handler for background/terminated messages (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: BeruwalaPizzaApp()));
}

final navigatorKey = GlobalKey<NavigatorState>();

class BeruwalaPizzaApp extends StatefulWidget {
  const BeruwalaPizzaApp({super.key});

  @override
  State<BeruwalaPizzaApp> createState() => _BeruwalaPizzaAppState();
}

class _BeruwalaPizzaAppState extends State<BeruwalaPizzaApp> {
  @override
  void initState() {
    super.initState();
    NotificationService().setupForegroundListener(navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
