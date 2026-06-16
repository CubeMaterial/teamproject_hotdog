import '../repositories/dashboard_repository.dart';

class DeleteCommentsUseCase {
  const DeleteCommentsUseCase(this.repository);

  final DashboardRepository repository;

  Future<void> call(Iterable<String> commentIds) async {
    await Future.wait([
      for (final commentId in commentIds) repository.deleteComment(commentId),
    ]);
  }
}
