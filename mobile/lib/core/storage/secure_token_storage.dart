import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'payspin_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? payspinSecureStorage;

  final FlutterSecureStorage _storage;
  static const _key = 'payspin_access_token';

  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> delete() => _storage.delete(key: _key);
  Future<String?> read() => readSecureStorage(_storage, _key);
  Future<bool> hasToken() async {
    final t = await read();
    return t != null && t.isNotEmpty;
  }
}
