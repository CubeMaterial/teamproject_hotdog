import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../../../core/network/model_mapper.dart';
import '../models/sales_order_model.dart';

class SalesOrderRemoteDataSource {
  SalesOrderRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SalesOrderModel>> getSalesOrders() async {
    final data = await _apiClient.getList(ApiRoutes.salesOrders);

    return ModelMapper.mapList(
      data,
      SalesOrderModel.fromJson,
      label: 'sales-orders',
    );
  }
}
