import 'package:payspin_mobile/core/storage/secure_token_storage.dart';

/// In-memory [SecureTokenStorage] so tests never touch the platform keychain.
class FakeTokenStorage extends SecureTokenStorage {
  FakeTokenStorage([this._token]);

  String? _token;
  int deleteCount = 0;
  int writeCount = 0;

  @override
  Future<void> write(String token) async {
    _token = token;
    writeCount++;
  }

  @override
  Future<void> delete() async {
    _token = null;
    deleteCount++;
  }

  @override
  Future<String?> read() async => _token;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;
}
