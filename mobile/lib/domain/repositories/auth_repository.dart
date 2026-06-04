import '../entities/auth_session.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<bool> hasSession();
  Future<User?> currentUser();
  Future<AuthSession> register({required String email, required String password, String? displayName});
  Future<AuthSession> login({required String email, required String password});

  /// Phone-first sign-in: the verified Firebase [idToken] resolves to a single
  /// account on the backend (logs in when it already exists, creates it once
  /// otherwise). [displayName] is only applied when the account is created.
  Future<AuthSession> phoneSignIn({required String idToken, String? displayName});
  Future<void> signOut();
  Future<User> updateDisplayName(String name);
}
