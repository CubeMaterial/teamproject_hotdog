import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../../../core/network/model_mapper.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderRemoteDataSource {
  PurchaseOrderRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PurchaseOrderModel>> getPurchaseOrders() async {
    final data = await _apiClient.getList(ApiRoutes.purchaseOrders);

    return ModelMapper.mapList(
      data,
      PurchaseOrderModel.fromJson,
      label: 'purchase-orders',
    );
  }
}
