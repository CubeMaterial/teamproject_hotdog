import '../repositories/dashboard_repository.dart';

class GetInventoryMakersUseCase {
  const GetInventoryMakersUseCase(this.repository);

  final DashboardRepository repository;

  Future<List<String>> call() => repository.getInventoryMakers();
}
