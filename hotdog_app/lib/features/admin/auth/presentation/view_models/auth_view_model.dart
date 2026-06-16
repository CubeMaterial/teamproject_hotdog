import 'package:flutter/foundation.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/login_admin_usecase.dart';
import '../../domain/usecases/logout_admin_usecase.dart';
import '../../domain/usecases/restore_admin_session_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required LoginAdminUseCase loginAdminUseCase,
    required LogoutAdminUseCase logoutAdminUseCase,
    required RestoreAdminSessionUseCase restoreAdminSessionUseCase,
  }) : _loginAdminUseCase = loginAdminUseCase,
       _logoutAdminUseCase = logoutAdminUseCase,
       _restoreAdminSessionUseCase = restoreAdminSessionUseCase {
    restoreSession();
  }

  final LoginAdminUseCase _loginAdminUseCase;
  final LogoutAdminUseCase _logoutAdminUseCase;
  final RestoreAdminSessionUseCase _restoreAdminSessionUseCase;

  AuthSession? _session;
  bool _isLoading = false;
  String? _errorMessage;

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _session = await _restoreAdminSessionUseCase();
    notifyListeners();
  }

  Future<bool> login({
    required String loginId,
    required String password,
    required bool rememberMe,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _session = await _loginAdminUseCase(
        loginId: loginId,
        password: password,
        rememberMe: rememberMe,
      );
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '로그인 중 문제가 발생했습니다.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _logoutAdminUseCase();
    _session = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
