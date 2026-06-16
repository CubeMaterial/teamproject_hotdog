import '../entities/staff.dart';
import '../repositories/dashboard_repository.dart';

class GetStaffsUseCase {
  const GetStaffsUseCase(this.repository);
  final DashboardRepository repository;
  Future<List<Staff>> call() => repository.getStaffs();
}
