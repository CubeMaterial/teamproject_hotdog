import '../repositories/dashboard_repository.dart';

class VerifyStaffPasswordUseCase {
  const VerifyStaffPasswordUseCase(this.repository);

  final DashboardRepository repository;

  Future<void> call({
    required String staffSeq,
    required String currentPassword,
  }) {
    return repository.verifyStaffPassword(
      staffSeq: staffSeq,
      currentPassword: currentPassword,
    );
  }
}
