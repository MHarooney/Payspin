import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/payspin_api_client.dart';
import 'firebase_bootstrap.dart';

/// Maps raw Firebase / device-attestation errors to payer-friendly copy.
String friendlyPhoneAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('blocked') || lower.contains('too many')) {
    return 'Too many attempts. Wait a few minutes, or use a test number.';
  }
  if (lower.contains('recaptcha') ||
      lower.contains('app verification') ||
      lower.contains('integrity') ||
      lower.contains('safetynet') ||
      lower.contains('missing-client-identifier')) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'We couldn’t verify this device with Google Play. Register '
            'this build’s SHA-256 in Firebase and enable Play Integrity, or '
            'use a test number to continue.';
      case TargetPlatform.iOS:
        return 'We couldn’t verify this device. Update to the latest build, '
            'try a physical device, or use a test number to continue.';
      default:
        return 'We couldn’t verify this device for phone sign-in. Use a test '
            'number to continue.';
    }
  }
  if (lower.contains('network')) {
    return 'Network error. Check your connection and try again.';
  }
  return message;
}

/// Real SMS verification via Firebase Phone Auth, replacing the demo stub when
/// Firebase is configured. When unavailable, [available] is false and callers
/// fall back to the legacy [VerifyOtpUseCase] so onboarding still works.
class PhoneAuthService {
  PhoneAuthService(this._api);

  final PayspinApiClient _api;
  String? _verificationId;
  int? _forceResendingToken;

  bool get available => FirebaseBootstrap.available;

  /// The Firebase `verificationId` from the last [sendCode], if any. Persisted
  /// by the OTP flow so it survives an app restart during reCAPTCHA.
  String? get pendingVerificationId => _verificationId;

  /// Re-seeds the verification id after a cold start so [confirmCode] can run
  /// without re-triggering reCAPTCHA. The id may have expired server-side, in
  /// which case [confirmCode] fails gracefully and the user can resend.
  void restorePendingVerification(String verificationId) {
    _verificationId = verificationId;
  }

  /// Kicks off SMS delivery. Callbacks mirror Firebase's verifyPhoneNumber.
  /// Pass [forceResending] true when the user taps Resend (uses Firebase's
  /// resend token from the prior [codeSent] callback).
  Future<void> sendCode(
    String phoneE164, {
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function()? onAutoVerified,
    bool forceResending = false,
  }) async {
    if (!available) {
      onError('Phone verification is not available');
      return;
    }
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneE164,
        forceResendingToken: forceResending ? _forceResendingToken : null,
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            onAutoVerified?.call();
          } catch (e) {
            debugPrint('PhoneAuth auto-verify signIn failed: $e');
          }
        },
        verificationFailed: (e) {
          debugPrint('PhoneAuth verificationFailed: ${e.code} ${e.message}');
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (verificationId, forceResendingToken) {
          _verificationId = verificationId;
          _forceResendingToken = forceResendingToken;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('PhoneAuth sendCode failed: $e');
      onError('$e');
    }
  }

  /// Verifies the entered SMS code. Returns true when Firebase accepts it.
  /// If a Payspin session already exists, also associates the phone server-side.
  /// True when [confirmCode] can run (Firebase initialized and id present).
  bool get canConfirmCode => available && _verificationId != null;

  Future<bool> confirmCode(String smsCode) async {
    if (!available || _verificationId == null) {
      debugPrint('confirmCode: no verificationId (available=$available)');
      return false;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _associateIfSignedIn();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('confirmCode FirebaseAuthException: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('confirmCode failed: $e');
      return false;
    }
  }

  /// The Firebase ID token for the currently phone-verified user, or null when
  /// Firebase is unavailable or no phone sign-in has happened. Used to exchange
  /// the verified phone for a Payspin session via `/auth/phone`.
  Future<String?> currentIdToken() async {
    if (!available) return null;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.phoneNumber == null) return null;
      return await user!.getIdToken();
    } catch (e) {
      debugPrint('currentIdToken failed: $e');
      return null;
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
