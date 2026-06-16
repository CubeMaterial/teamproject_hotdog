import '../entities/inventory.dart';
import '../repositories/dashboard_repository.dart';

class GetInventoryItemsUseCase {
  const GetInventoryItemsUseCase(this.repository);
  final DashboardRepository repository;
  Future<List<InventoryItem>> call() => repository.getInventoryItems();
}
