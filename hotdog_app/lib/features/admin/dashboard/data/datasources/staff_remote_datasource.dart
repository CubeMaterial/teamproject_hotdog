import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../../../core/network/model_mapper.dart';
import '../../domain/entities/staff_creation_result.dart';
import '../models/staff_model.dart';

class StaffRemoteDataSource {
  StaffRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<StaffModel>> getStaffs() async {
    final data = await _apiClient.getList(ApiRoutes.staffs);

    return ModelMapper.mapList(data, StaffModel.fromJson, label: 'staffs');
  }

  Future<StaffCreationResult> createStaff({
    required String staffName,
    required String staffId,
    required String staffPhone,
    required int staffLevel,
  }) async {
    final data = await _apiClient.postMap(
      ApiRoutes.staffs,
      body: {
        'staffName': staffName,
        'staffId': staffId,
        'staffPhone': staffPhone,
        'staffLevel': staffLevel,
      },
    );

    final staffJson = data['staff'];
    if (staffJson is! Map<String, dynamic>) {
      throw Exception('직원 등록 응답에 직원 정보가 없습니다.');
    }

    final emailJson = data['email'];
    final email = emailJson is Map<String, dynamic>
        ? emailJson
        : <String, dynamic>{};

    return StaffCreationResult(
      staff: StaffModel.fromJson(staffJson),
      emailSent: email['sent'] == true,
      emailSubject: '${email['subject'] ?? ''}',
      emailBody: '${email['body'] ?? ''}',
      emailWarning: '${email['warning'] ?? ''}',
    );
  }

  Future<StaffModel> updateStaffPhone({
    required String staffSeq,
    required String staffPhone,
  }) async {
    final data = await _apiClient.patchMap(
      '${ApiRoutes.staffs}$staffSeq/phone',
      body: {'staffPhone': staffPhone},
    );

    final staffJson = data['staff'];
    if (staffJson is! Map<String, dynamic>) {
      throw Exception('직원 연락처 수정 응답에 직원 정보가 없습니다.');
    }

    return StaffModel.fromJson(staffJson);
  }

  Future<void> updateStaffPassword({
    required String staffSeq,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.patchMap(
      '${ApiRoutes.staffs}$staffSeq/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> verifyStaffPassword({
    required String staffSeq,
    required String currentPassword,
  }) async {
    await _apiClient.postMap(
      '${ApiRoutes.staffs}$staffSeq/password/verify',
      body: {'currentPassword': currentPassword},
    );
  }

  Future<void> deleteStaff(String staffSeq) async {
    await _apiClient.deleteMap('${ApiRoutes.staffs}$staffSeq');
  }
}
