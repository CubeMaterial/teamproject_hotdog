import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RestoreAdminSessionUseCase {
  const RestoreAdminSessionUseCase(this.repository);

  final AuthRepository repository;

  Future<AuthSession?> call() => repository.restoreSession();
}
