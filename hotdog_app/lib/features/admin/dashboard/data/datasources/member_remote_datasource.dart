import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../../../core/network/model_mapper.dart';
import '../models/member_model.dart';

class MemberRemoteDataSource {
  MemberRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MemberModel>> getMembers() async {
    final data = await _apiClient.getList(ApiRoutes.members);

    return ModelMapper.mapList(data, MemberModel.fromJson, label: 'members');
  }
}
