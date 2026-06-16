import 'package:get_storage/get_storage.dart';

import '../../domain/entities/auth_session.dart';
import '../storage/login_get_storage.dart';
import '../storage/login_storage_keys.dart';

class AuthLocalStorage {
  AuthLocalStorage({LoginGetStorage? loginStorage, GetStorage? storage})
    : _loginStorage = loginStorage ?? LoginGetStorage(storage: storage);

  final LoginGetStorage _loginStorage;

  Future<AuthSession?> readSession() async {
    final value = await _loginStorage.read<Map<dynamic, dynamic>>(
      LoginStorageKeys.session,
    );
    return AuthSession.fromJson(value);
  }

  Future<void> writeSession(AuthSession session) async {
    return _loginStorage.write(LoginStorageKeys.session, session.toJson());
  }

  Future<void> clearSession() async {
    return _loginStorage.remove(LoginStorageKeys.session);
  }
}
