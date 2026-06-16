import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../../../core/network/model_mapper.dart';
import '../models/inventory_model.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<InventoryModel>> getInventoryItems() async {
    final data = await _apiClient.getList(ApiRoutes.inventory);

    return ModelMapper.mapList(
      data,
      InventoryModel.fromJson,
      label: 'inventory',
    );
  }

  Future<List<StockHistoryModel>> getStockHistories() async {
    final data = await _apiClient.getList(ApiRoutes.inventoryHistories);

    return ModelMapper.mapList(
      data,
      StockHistoryModel.fromJson,
      label: 'inventory histories',
    );
  }

  Future<List<String>> getInventoryMakers() async {
    final data = await _apiClient.getList(ApiRoutes.inventoryMakers);
    final makers = <String>[];

    for (final item in data) {
      if (item is! Map) {
        continue;
      }

      final maker = '${item['makerName'] ?? item['maker_name'] ?? ''}'.trim();
      if (maker.isNotEmpty && !makers.contains(maker)) {
        makers.add(maker);
      }
    }

    return makers;
  }

  Future<InventoryModel> createInventoryItem({
    required String name,
    required String category,
    required String maker,
    required int price,
    required int stock,
  }) async {
    final data = await _apiClient.postMap(
      ApiRoutes.inventory,
      body: {
        'name': name,
        'category': category,
        'maker': maker,
        'price': price,
        'stock': stock,
      },
    );

    return InventoryModel.fromJson(data);
  }

  Future<List<String>> getInventoryCategories() async {
    final data = await _apiClient.getList(ApiRoutes.inventoryCategories);
    final categories = <String>[];

    for (final item in data) {
      if (item is! Map) {
        continue;
      }

      final category =
          '${item['category'] ?? item['product_sub_category_name'] ?? item['product_category_name'] ?? ''}'
              .trim();
      if (category.isNotEmpty && !categories.contains(category)) {
        categories.add(category);
      }
    }

    return categories;
  }
}
