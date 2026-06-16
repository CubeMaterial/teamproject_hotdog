import '../entities/refund.dart';
import '../repositories/dashboard_repository.dart';

class GetRefundsUseCase {
  const GetRefundsUseCase(this.repository);
  final DashboardRepository repository;
  Future<List<Refund>> call() => repository.getRefunds();
}
