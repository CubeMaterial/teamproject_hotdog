import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase(this.repository);

  final DashboardRepository repository;

  Future<DashboardSummary> call() => repository.getDashboardSummary();
}
