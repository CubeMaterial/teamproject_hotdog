import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../core/network/api_client.dart';
import '../../data/datasources/auth_local_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/storage/login_get_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_admin_usecase.dart';
import '../../domain/usecases/logout_admin_usecase.dart';
import '../../domain/usecases/restore_admin_session_usecase.dart';
import '../../temp/temporary_admin_credentials.dart';
import '../view_models/auth_view_model.dart';

final loginGetStorageProvider = Provider<LoginGetStorage>((ref) {
  return LoginGetStorage();
});

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  return AuthLocalStorage(loginStorage: ref.watch(loginGetStorageProvider));
});

final temporaryAdminCredentialsProvider = Provider<TemporaryAdminCredentials>((
  ref,
) {
  return const TemporaryAdminCredentials();
});

final authApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(authApiClientProvider);

  return AuthRemoteDataSource(
    apiClient: apiClient,
    temporaryAdminCredentials: ref.watch(temporaryAdminCredentialsProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localStorage: ref.watch(authLocalStorageProvider),
  );
});

final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return AuthViewModel(
    loginAdminUseCase: LoginAdminUseCase(repository),
    logoutAdminUseCase: LogoutAdminUseCase(repository),
    restoreAdminSessionUseCase: RestoreAdminSessionUseCase(repository),
  );
});
