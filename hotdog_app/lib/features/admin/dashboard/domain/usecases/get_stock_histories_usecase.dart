import '../entities/inventory.dart';
import '../repositories/dashboard_repository.dart';

class GetStockHistoriesUseCase {
  const GetStockHistoriesUseCase(this.repository);

  final DashboardRepository repository;

  Future<List<StockHistory>> call() => repository.getStockHistories();
}
