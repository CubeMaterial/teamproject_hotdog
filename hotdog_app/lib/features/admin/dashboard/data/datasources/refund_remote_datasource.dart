import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../../../core/network/model_mapper.dart';
import '../models/refund_model.dart';

class RefundRemoteDataSource {
  RefundRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<RefundModel>> getRefunds() async {
    final data = await _apiClient.getList(ApiRoutes.refunds);

    return ModelMapper.mapList(data, RefundModel.fromJson, label: 'refunds');
  }

  Future<void> updateRefundStatus({
    required String refundId,
    required String action,
  }) async {
    await _apiClient.patchMap(
      ApiRoutes.refundStatus(refundId),
      body: {'action': action},
    );
  }
}
