import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/payspin_api_client.dart';
import '../mappers/api_mappers.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final PayspinApiClient _api;
  User? _cachedUser;

  @override
  Future<bool> hasSession() => _api.hasToken();

  @override
  Future<User?> currentUser() async {
    if (!await _api.hasToken()) return null;
    try {
      _cachedUser = mapUser(await _api.getMe());
      return _cachedUser;
    } catch (_) {
      return _cachedUser;
    }
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final json = await _api.register(email: email, password: password, displayName: displayName);
    final session = mapAuthSession(json);
    _cachedUser = session.user;
    return session;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    final json = await _api.login(email: email, password: password);
    final session = mapAuthSession(json);
    _cachedUser = session.user;
    return session;
  }

  @override
  Future<void> signOut() async {
    await _api.signOut();
    _cachedUser = null;
  }

  @override
  Future<User> updateDisplayName(String name) async {
    _cachedUser = mapUser(await _api.updateProfile(displayName: name));
    return _cachedUser!;
  }
}
