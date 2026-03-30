import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyOtp() {
    if (_otpController.text.length != 6) return;
    final phoneNumber = ModalRoute.of(context)!.settings.arguments as String;
    ref
        .read(phoneAuthProvider.notifier)
        .verifyOtp(_otpController.text, phoneNumber);
  }

  void _resendOtp() {
    final phoneNumber = ModalRoute.of(context)!.settings.arguments as String;
    ref.read(phoneAuthProvider.notifier).sendOtp(phoneNumber);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final phoneState = ref.watch(phoneAuthProvider);
    final phoneNumber = ModalRoute.of(context)!.settings.arguments as String;

    ref.listen<PhoneAuthState>(phoneAuthProvider, (prev, next) {
      if (next.otpState == OtpState.verified) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
      if (next.otpState == OtpState.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your\nphone number',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to $phoneNumber',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                controller: _otpController,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.white,
                  inactiveFillColor: AppColors.white,
                  selectedFillColor: AppColors.white,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.textGrey.withValues(alpha: 0.3),
                  selectedColor: AppColors.accent,
                ),
                enableActiveFill: true,
                onCompleted: (_) => _verifyOtp(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: phoneState.otpState == OtpState.verifying
                      ? null
                      : _verifyOtp,
                  child: phoneState.otpState == OtpState.verifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: _countdown > 0
                    ? Text(
                        'Resend code in ${_countdown}s',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : TextButton(
                        onPressed: _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
