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

  Future<PurchaseOrderModel> createPurchaseOrder({
    required String vendor,
    required String itemName,
    required int quantity,
    required DateTime createdAt,
  }) async {
    final data = await _apiClient.postMap(
      ApiRoutes.purchaseOrders,
      body: {
        'vendor': vendor,
        'item_name': itemName,
        'quantity': quantity,
        'created_at': _formatDate(createdAt),
      },
    );

    return PurchaseOrderModel.fromJson(data);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
