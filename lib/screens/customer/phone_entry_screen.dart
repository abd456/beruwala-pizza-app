import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '${AppConstants.countryCode}${_phoneController.text.trim()}';

    // This calls FirebaseAuth.verifyPhoneNumber behind the scenes.
    // Provider is in lib/providers/auth_provider.dart — class PhoneAuthNotifier.
    await ref.read(phoneAuthProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(phoneAuthProvider);

    // When OTP is sent, navigate to OTP screen
    ref.listen(phoneAuthProvider, (_, next) {
      if (next.otpState == OtpState.sent) {
        Navigator.pushNamed(
          context,
          AppRoutes.otp,
          arguments: _phoneController.text.trim(),
        );
      }
      // Auto-verified (e.g. on emulator or same device)
      if (next.otpState == OtpState.verified) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    });

    final isSending = otpState.otpState == OtpState.sending;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SizedBox(
            height: double.infinity,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const SizedBox(height: 32),
              Text(
                'Enter your phone number',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll send you a verification code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '${AppConstants.countryCode} ',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => v == null || v.trim().length < 9
                    ? 'Enter a valid Sri Lankan mobile number (9 digits)'
                    : null,
              ),
              if (otpState.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  otpState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSending ? null : _sendOtp,
                  child: isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Send Code'),
                ),
              ),
              const Spacer(),
              // Staff login link — visible but unobtrusive
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.staffLogin,
                  ),
                  child: Text(
                    'Staff Login',
                    style: TextStyle(
                      color: AppColors.textGrey.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
