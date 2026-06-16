import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../dashboard/data/models/staff_model.dart';
import '../../../dashboard/domain/entities/staff.dart';
import '../../temp/temporary_admin_credentials.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required this.apiClient,
    required this.temporaryAdminCredentials,
  });

  final ApiClient apiClient;
  final TemporaryAdminCredentials temporaryAdminCredentials;

  Future<Staff> login({
    required String loginId,
    required String password,
  }) async {
    if (loginId.trim().toLowerCase() == TemporaryAdminCredentials.loginId) {
      if (!temporaryAdminCredentials.matches(
        loginId: loginId,
        password: password,
      )) {
        throw const AuthException('아이디 또는 비밀번호가 올바르지 않습니다.');
      }

      return StaffModel(
        staffSeq: TemporaryAdminCredentials.staffSeq,
        staffName: TemporaryAdminCredentials.staffName,
        staffPhone: '',
        staffId: TemporaryAdminCredentials.loginId,
        staffPw: '',
        staffDate: DateTime.now(),
        staffLevel: 9,
        staffSuperSeq: '',
        staffEmail: TemporaryAdminCredentials.loginId,
      );
    }

    try {
      final data = await apiClient.postMap(
        ApiRoutes.login,
        body: {'login_id': loginId.trim(), 'password': password},
      );
      final staffJson = data['staff'];
      if (staffJson is Map<String, dynamic>) {
        return StaffModel.fromJson(staffJson);
      }
    } catch (_) {
      throw const AuthException('아이디 또는 비밀번호가 올바르지 않습니다.');
    }

    throw const AuthException('관리자 계정을 찾을 수 없습니다.');
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}
