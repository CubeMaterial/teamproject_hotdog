import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginAdminUseCase {
  const LoginAdminUseCase(this.repository);

  final AuthRepository repository;

  Future<AuthSession> call({
    required String loginId,
    required String password,
    required bool rememberMe,
  }) {
    return repository.login(
      loginId: loginId,
      password: password,
      rememberMe: rememberMe,
    );
  }
}
