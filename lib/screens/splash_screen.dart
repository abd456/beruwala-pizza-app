import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';
import '../services/notification_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _minDelayDone = false;
  bool _authResolved = false;
  User? _resolvedUser;

  @override
  void initState() {
    super.initState();
    _startMinDelay();
    _waitForAuth();
  }

  void _startMinDelay() {
    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (!mounted) return;
      _minDelayDone = true;
      _tryNavigate();
    });
  }

  Future<void> _waitForAuth() async {
    try {
      final user = await ref.read(authStateProvider.future);
      if (!mounted) return;
      _resolvedUser = user;
    } catch (_) {
      // Auth error — treat as logged out
    }
    if (!mounted) return;
    _authResolved = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (_navigated || !mounted || !_minDelayDone || !_authResolved) return;
    _doNavigate(_resolvedUser);
  }

  Future<void> _doNavigate(User? user) async {
    if (_navigated || !mounted) return;
    _navigated = true;

    if (user != null) {
      await NotificationService().init(user.uid);
      final authService = ref.read(authServiceProvider);
      final userModel = await authService.getUserFromFirestore(user.uid);
      if (!mounted) return;

      if (userModel?.isAdmin == true) {
        Navigator.pushReplacementNamed(context, AppRoutes.ordersDashboard);
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_tp.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.tagline,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
