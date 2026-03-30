import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;

    // If admin is logged in, go to dashboard
    if (user != null) {
      final authService = ref.read(authServiceProvider);
      final userModel = await authService.getUserFromFirestore(user.uid);
      if (!mounted) return;

      if (userModel?.isAdmin == true) {
        Navigator.pushReplacementNamed(context, AppRoutes.ordersDashboard);
        return;
      }
    }

    // Everyone else (logged in customer or guest) goes to menu
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _onLogoTap() {
    _tapCount++;
    if (_tapCount >= AppConstants.staffAccessTapCount) {
      _tapCount = 0;
      Navigator.pushNamed(context, AppRoutes.staffLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _onLogoTap,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_pizza,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
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
