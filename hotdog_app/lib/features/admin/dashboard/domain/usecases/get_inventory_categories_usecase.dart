import '../repositories/dashboard_repository.dart';

class GetInventoryCategoriesUseCase {
  const GetInventoryCategoriesUseCase(this.repository);

  final DashboardRepository repository;

  Future<List<String>> call() => repository.getInventoryCategories();
}
