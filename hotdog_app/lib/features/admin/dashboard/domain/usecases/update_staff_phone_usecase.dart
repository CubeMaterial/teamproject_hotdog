import '../entities/staff.dart';
import '../repositories/dashboard_repository.dart';

class UpdateStaffPhoneUseCase {
  const UpdateStaffPhoneUseCase(this.repository);

  final DashboardRepository repository;

  Future<Staff> call({required String staffSeq, required String staffPhone}) {
    return repository.updateStaffPhone(
      staffSeq: staffSeq,
      staffPhone: staffPhone,
    );
  }
}
