import '../entities/staff_creation_result.dart';
import '../repositories/dashboard_repository.dart';

class CreateStaffUseCase {
  const CreateStaffUseCase(this.repository);

  final DashboardRepository repository;

  Future<StaffCreationResult> call({
    required String staffName,
    required String staffId,
    required String staffPhone,
    required int staffLevel,
  }) {
    return repository.createStaff(
      staffName: staffName,
      staffId: staffId,
      staffPhone: staffPhone,
      staffLevel: staffLevel,
    );
  }
}
