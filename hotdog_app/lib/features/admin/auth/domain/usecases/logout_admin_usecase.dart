import '../repositories/auth_repository.dart';

class LogoutAdminUseCase {
  const LogoutAdminUseCase(this.repository);

  final AuthRepository repository;

  Future<void> call() => repository.logout();
}
