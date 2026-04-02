import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: user == null
            ? _GuestView(
                onLogin: () =>
                    Navigator.pushNamed(context, AppRoutes.phoneEntry),
              )
            : _LoggedInView(
                email: user.email ?? '',
                uid: user.uid,
                onLogout: () async {
                  await ref.read(authServiceProvider).signOut();
                },
              ),
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  final VoidCallback onLogin;
  const _GuestView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: AppColors.textGrey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re not logged in',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to place orders and track them',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onLogin,
            child: const Text('Sign In / Sign Up'),
          ),
        ],
      ),
    );
  }
}

class _LoggedInView extends ConsumerWidget {
  final String email;
  final String uid;
  final VoidCallback onLogout;

  const _LoggedInView({
    required this.email,
    required this.uid,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the user's name from Firestore
    // userModelProvider is defined in lib/providers/auth_provider.dart
    // It returns AsyncValue<UserModel?> — UserModel has fields: uid, name, phone, role
    final userModel = ref.watch(userModelProvider);
    final displayName = userModel.valueOrNull?.name ?? '';
    final displayPhone = userModel.valueOrNull?.phone ?? '';

    return Column(
      children: [
        const SizedBox(height: 20),

        // Avatar with first letter of name or email
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          child: Text(
            displayName.isNotEmpty
                ? displayName[0].toUpperCase()
                : (email.isNotEmpty ? email[0].toUpperCase() : 'U'),
            style: const TextStyle(
              fontSize: 32,
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Show name if available, fallback to email
        Text(
          displayName.isNotEmpty ? displayName : email,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),

        if (displayPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            displayPhone,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textGrey),
          ),
        ],

        const SizedBox(height: 32),
        const Divider(),

        // My Orders tile
        ListTile(
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
          ),
          title: const Text('My Orders'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.myOrders),
        ),

        const Divider(),

        // Logout tile
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: onLogout,
        ),
      ],
    );
  }
}
