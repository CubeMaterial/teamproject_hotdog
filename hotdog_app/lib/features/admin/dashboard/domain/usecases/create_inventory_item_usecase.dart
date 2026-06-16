import '../entities/inventory.dart';
import '../repositories/dashboard_repository.dart';

class CreateInventoryItemUseCase {
  const CreateInventoryItemUseCase(this.repository);

  final DashboardRepository repository;

  Future<InventoryItem> call({
    required String name,
    required String category,
    required String maker,
    required int price,
    required int stock,
  }) {
    return repository.createInventoryItem(
      name: name,
      category: category,
      maker: maker,
      price: price,
      stock: stock,
    );
  }
}
