import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({
    required String loginId,
    required String password,
    required bool rememberMe,
  });

  Future<void> logout();
}
