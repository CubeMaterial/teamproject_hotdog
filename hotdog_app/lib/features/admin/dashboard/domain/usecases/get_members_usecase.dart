import '../entities/member.dart';
import '../repositories/dashboard_repository.dart';

class GetMembersUseCase {
  const GetMembersUseCase(this.repository);
  final DashboardRepository repository;
  Future<List<Member>> call() => repository.getMembers();
}
