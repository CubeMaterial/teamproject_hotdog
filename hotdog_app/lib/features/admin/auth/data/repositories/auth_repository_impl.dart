import '../datasources/auth_local_storage.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalStorage localStorage;

  @override
  Future<AuthSession?> restoreSession() => localStorage.readSession();

  @override
  Future<AuthSession> login({
    required String loginId,
    required String password,
    required bool rememberMe,
  }) async {
    final staff = await remoteDataSource.login(
      loginId: loginId,
      password: password,
    );
    final session = AuthSession(
      staffSeq: staff.staffSeq,
      staffEmail: staff.email,
      rememberMe: rememberMe,
      createdAt: DateTime.now(),
    );

    if (rememberMe) {
      await localStorage.writeSession(session);
    } else {
      await localStorage.clearSession();
    }

    return session;
  }

  @override
  Future<void> logout() => localStorage.clearSession();
}
