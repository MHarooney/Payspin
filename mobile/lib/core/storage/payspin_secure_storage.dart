import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared keychain / Keystore settings for Payspin.
///
/// iOS Simulator can hang indefinitely on default keychain access; use
/// [KeychainAccessibility.first_unlock_this_device] and always time out reads
/// at call sites (see [readWithTimeout]).
const FlutterSecureStorage payspinSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Reads a secure-storage value with a hard ceiling so startup never blocks
/// the first Flutter frame (common on the iOS Simulator).
Future<String?> readSecureStorage(
  FlutterSecureStorage storage,
  String key, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    return await storage.read(key: key).timeout(timeout);
  } catch (_) {
    return null;
  }
}
