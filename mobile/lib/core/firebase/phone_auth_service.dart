import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/payspin_api_client.dart';
import 'firebase_bootstrap.dart';

/// Real SMS verification via Firebase Phone Auth, replacing the demo stub when
/// Firebase is configured. When unavailable, [available] is false and callers
/// fall back to the legacy [VerifyOtpUseCase] so onboarding still works.
class PhoneAuthService {
  PhoneAuthService(this._api);

  final PayspinApiClient _api;
  String? _verificationId;

  bool get available => FirebaseBootstrap.available;

  /// Kicks off SMS delivery. Callbacks mirror Firebase's verifyPhoneNumber.
  Future<void> sendCode(
    String phoneE164, {
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function()? onAutoVerified,
  }) async {
    if (!available) {
      onError('Phone verification is not available');
      return;
    }
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneE164,
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            onAutoVerified?.call();
          } catch (_) {/* fall through to manual entry */}
        },
        verificationFailed: (e) => onError(e.message ?? 'Verification failed'),
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError('$e');
    }
  }

  /// Verifies the entered SMS code. Returns true when Firebase accepts it.
  /// If a Payspin session already exists, also associates the phone server-side.
  Future<bool> confirmCode(String smsCode) async {
    if (!available || _verificationId == null) return false;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _associateIfSignedIn();
      return true;
    } catch (e) {
      debugPrint('confirmCode failed: $e');
      return false;
    }
  }

  /// Best-effort: if the user is both Payspin-authenticated and Firebase
  /// phone-verified, persist the verified phone on their profile. Safe to call
  /// repeatedly (e.g. on app start after onboarding created the account).
  Future<void> syncVerifiedPhone() async {
    if (!available) return;
    if (!await _api.hasToken()) return;
    await _associateIfSignedIn();
  }

  Future<void> _associateIfSignedIn() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.phoneNumber == null) return;
      if (!await _api.hasToken()) return; // associate later once logged in
      final idToken = await user!.getIdToken();
      if (idToken != null) await _api.verifyPhone(idToken: idToken);
    } catch (e) {
      debugPrint('phone association deferred: $e');
    }
  }
}
