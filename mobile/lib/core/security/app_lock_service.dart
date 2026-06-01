import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// The strongest enrolled local-auth method, used to choose the priority
/// unlock affordance: Face ID → fingerprint/Touch ID → app passcode.
enum BiometricKind { faceId, touchId, faceUnlock, fingerprint, iris, none }

/// Snapshot of what the device can do, computed once and reused by the
/// setup and lock screens so they stay in sync.
@immutable
class LockCapability {
  const LockCapability({
    required this.deviceSupported,
    required this.canCheckBiometrics,
    required this.kind,
    required this.enrolled,
  });

  /// Device has *some* local auth (biometrics OR device passcode/PIN/pattern).
  final bool deviceSupported;

  /// Hardware can check biometrics (not necessarily enrolled).
  final bool canCheckBiometrics;

  /// The priority biometric to surface (face > fingerprint).
  final BiometricKind kind;

  /// At least one biometric is enrolled and usable.
  final bool enrolled;

  bool get hasBiometrics => enrolled && kind != BiometricKind.none;

  /// Human label for the priority method, platform-aware (Face ID/Touch ID on
  /// iOS, Face Unlock/Fingerprint on Android).
  String get label {
    switch (kind) {
      case BiometricKind.faceId:
        return 'Face ID';
      case BiometricKind.touchId:
        return 'Touch ID';
      case BiometricKind.faceUnlock:
        return 'Face Unlock';
      case BiometricKind.fingerprint:
        return 'Fingerprint';
      case BiometricKind.iris:
        return 'Iris';
      case BiometricKind.none:
        return 'Passcode';
    }
  }

  static const empty = LockCapability(
    deviceSupported: false,
    canCheckBiometrics: false,
    kind: BiometricKind.none,
    enrolled: false,
  );
}

/// Result of a biometric attempt so callers can react (fall back to passcode,
/// show a lockout message, or unlock).
enum BiometricResult { success, failedFallback, lockedOut, unavailable, canceled, error }

/// Owns everything about the app lock: capability detection, biometric
/// authentication, and a salted-hash passcode stored in the device keychain.
///
/// Priority chain (per product spec): Face → Fingerprint → app passcode.
class AppLockService {
  AppLockService({FlutterSecureStorage? storage, LocalAuthentication? localAuth})
      : _storage = storage ?? const FlutterSecureStorage(),
        _auth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  static const _kEnabled = 'payspin_lock_enabled';
  static const _kBiometric = 'payspin_lock_biometric';
  static const _kPinHash = 'payspin_lock_pin_hash';
  static const _kPinSalt = 'payspin_lock_pin_salt';
  static const _kDisplayName = 'payspin_lock_display_name';

  static const pinLength = 6;

  // ---------------------------------------------------------------------------
  // Capability detection
  // ---------------------------------------------------------------------------

  /// Detects device support and the priority biometric. Never throws — a
  /// failure degrades to passcode-only so onboarding is never blocked.
  Future<LockCapability> capability() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      var enrolled = const <BiometricType>[];
      if (canCheck) {
        enrolled = await _auth.getAvailableBiometrics();
      }
      return LockCapability(
        deviceSupported: supported,
        canCheckBiometrics: canCheck,
        kind: _priorityKind(enrolled),
        enrolled: enrolled.isNotEmpty,
      );
    } catch (e) {
      debugPrint('AppLock: capability check failed: $e');
      return LockCapability.empty;
    }
  }

  /// Face wins over fingerprint; maps to platform-specific naming.
  BiometricKind _priorityKind(List<BiometricType> types) {
    final isIOS = !kIsWeb && Platform.isIOS;
    if (types.contains(BiometricType.face)) {
      return isIOS ? BiometricKind.faceId : BiometricKind.faceUnlock;
    }
    if (types.contains(BiometricType.fingerprint)) {
      return isIOS ? BiometricKind.touchId : BiometricKind.fingerprint;
    }
    if (types.contains(BiometricType.iris)) return BiometricKind.iris;
    // `strong`/`weak` without a concrete type: assume fingerprint affordance.
    if (types.contains(BiometricType.strong) || types.contains(BiometricType.weak)) {
      return isIOS ? BiometricKind.touchId : BiometricKind.fingerprint;
    }
    return BiometricKind.none;
  }

  // ---------------------------------------------------------------------------
  // Biometric authentication
  // ---------------------------------------------------------------------------

  /// Runs a biometric prompt. [biometricOnly] keeps the OS from silently
  /// falling back to the device PIN — we want our own passcode as the fallback.
  Future<BiometricResult> authenticateBiometric({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failedFallback;
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.biometricLockout:
        case LocalAuthExceptionCode.temporaryLockout:
          return BiometricResult.lockedOut;
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        case LocalAuthExceptionCode.uiUnavailable:
          return BiometricResult.unavailable;
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
        case LocalAuthExceptionCode.userRequestedFallback:
          return BiometricResult.canceled;
        default:
          debugPrint('AppLock: biometric error ${e.code.name}: ${e.description}');
          return BiometricResult.error;
      }
    } catch (e) {
      debugPrint('AppLock: biometric unexpected error: $e');
      return BiometricResult.error;
    }
  }

  // ---------------------------------------------------------------------------
  // Passcode (salted SHA-256 in the keychain)
  // ---------------------------------------------------------------------------

  bool isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  String _newSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Persists the passcode and (optionally) enables biometrics + display name.
  Future<void> enableLock({
    required String pin,
    required bool biometricEnabled,
    String? displayName,
  }) async {
    final salt = _newSalt();
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: _hash(pin, salt));
    await _storage.write(key: _kBiometric, value: biometricEnabled ? '1' : '0');
    await _storage.write(key: _kEnabled, value: '1');
    if (displayName != null && displayName.trim().isNotEmpty) {
      await _storage.write(key: _kDisplayName, value: displayName.trim());
    }
  }

  /// Verifies an entered passcode against the stored salted hash.
  Future<bool> verifyPin(String pin) async {
    final salt = await _read(_kPinSalt);
    final hash = await _read(_kPinHash);
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  /// Reads a key, treating any keychain/platform failure as "absent" so the
  /// lock never hard-crashes the app on a storage glitch.
  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('AppLock: storage read failed for $key: $e');
      return null;
    }
  }

  /// Removes all lock material (used on logout / "forgot passcode").
  Future<void> disableLock() async {
    await Future.wait([
      _storage.delete(key: _kEnabled),
      _storage.delete(key: _kBiometric),
      _storage.delete(key: _kPinHash),
      _storage.delete(key: _kPinSalt),
      _storage.delete(key: _kDisplayName),
    ]);
  }

  Future<bool> isLockEnabled() async => (await _read(_kEnabled)) == '1';

  Future<bool> isBiometricEnabled() async => (await _read(_kBiometric)) == '1';

  Future<void> setBiometricEnabled(bool value) =>
      _storage.write(key: _kBiometric, value: value ? '1' : '0');

  Future<String?> displayName() => _read(_kDisplayName);

  Future<void> setDisplayName(String name) =>
      _storage.write(key: _kDisplayName, value: name.trim());
}
