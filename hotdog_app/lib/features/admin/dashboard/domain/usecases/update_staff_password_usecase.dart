import '../repositories/dashboard_repository.dart';

class UpdateStaffPasswordUseCase {
  const UpdateStaffPasswordUseCase(this.repository);

  final DashboardRepository repository;

  Future<void> call({
    required String staffSeq,
    required String currentPassword,
    required String newPassword,
  }) {
    return repository.updateStaffPassword(
      staffSeq: staffSeq,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
