import '../repositories/dashboard_repository.dart';

class DeleteStaffsUseCase {
  const DeleteStaffsUseCase(this.repository);

  final DashboardRepository repository;

  Future<void> call(Iterable<String> staffSeqs) async {
    await Future.wait([
      for (final staffSeq in staffSeqs) repository.deleteStaff(staffSeq),
    ]);
  }
}
