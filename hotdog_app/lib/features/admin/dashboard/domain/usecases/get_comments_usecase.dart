import '../entities/comment.dart';
import '../repositories/dashboard_repository.dart';

class GetCommentsUseCase {
  const GetCommentsUseCase(this.repository);
  final DashboardRepository repository;
  Future<List<AdminComment>> call() => repository.getComments();
}
