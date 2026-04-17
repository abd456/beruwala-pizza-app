import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user model from Firestore
final userModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;
  return ref.read(authServiceProvider).getUserFromFirestore(user.uid);
});

// Phone OTP state
enum OtpState { idle, sending, sent, verifying, verified, error }

class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  final AuthService _authService;

  PhoneAuthNotifier(this._authService) : super(const PhoneAuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(otpState: OtpState.sending, error: null);

    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        state = state.copyWith(
          otpState: OtpState.sent,
          verificationId: verificationId,
          resendToken: resendToken,
        );
      },
      onError: (error) {
        state = state.copyWith(otpState: OtpState.error, error: error);
      },
      onAutoVerify: (credential) async {
        state = state.copyWith(otpState: OtpState.verifying);
        try {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          await _ensureCustomerExists(userCredential, phoneNumber);
          state = state.copyWith(otpState: OtpState.verified);
        } catch (e) {
          state = state.copyWith(
              otpState: OtpState.error, error: e.toString());
        }
      },
      resendToken: state.resendToken,
    );
  }

  Future<void> verifyOtp(String otp, String phoneNumber) async {
    if (state.verificationId == null) return;
    state = state.copyWith(otpState: OtpState.verifying, error: null);

    try {
      final userCredential = await _authService.verifyOtp(
        verificationId: state.verificationId!,
        otp: otp,
      );
      await _ensureCustomerExists(userCredential, phoneNumber);
      state = state.copyWith(otpState: OtpState.verified);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        otpState: OtpState.error,
        error: e.message ?? 'Invalid OTP',
      );
    }
  }

  Future<void> _ensureCustomerExists(
      UserCredential cred, String phoneNumber) async {
    final uid = cred.user!.uid;
    final existingUser = await _authService.getUserFromFirestore(uid);
    if (existingUser == null) {
      await _authService.createCustomerInFirestore(
        uid: uid,
        name: cred.user!.displayName ?? 'Customer',
        phone: phoneNumber,
      );
    }
    // Register FCM token for push notifications
    await NotificationService().init(uid);
  }

  void reset() {
    state = const PhoneAuthState();
  }
}

class PhoneAuthState {
  final OtpState otpState;
  final String? verificationId;
  final int? resendToken;
  final String? error;

  const PhoneAuthState({
    this.otpState = OtpState.idle,
    this.verificationId,
    this.resendToken,
    this.error,
  });

  PhoneAuthState copyWith({
    OtpState? otpState,
    String? verificationId,
    int? resendToken,
    String? error,
  }) {
    return PhoneAuthState(
      otpState: otpState ?? this.otpState,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      error: error,
    );
  }
}

final phoneAuthProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>((ref) {
  return PhoneAuthNotifier(ref.read(authServiceProvider));
});
