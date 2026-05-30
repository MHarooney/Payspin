import '../entities/auth_session.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<bool> hasSession();
  Future<User?> currentUser();
  Future<AuthSession> register({required String email, required String password, String? displayName});
  Future<AuthSession> login({required String email, required String password});
  Future<void> signOut();
  Future<User> updateDisplayName(String name);
}
