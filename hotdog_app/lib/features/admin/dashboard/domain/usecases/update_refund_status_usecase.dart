import '../repositories/dashboard_repository.dart';

class UpdateRefundStatusUseCase {
  const UpdateRefundStatusUseCase(this.repository);

  final DashboardRepository repository;

  Future<void> call({required String refundId, required String action}) {
    return repository.updateRefundStatus(refundId: refundId, action: action);
  }
}
