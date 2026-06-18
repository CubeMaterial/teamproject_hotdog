import '../entities/purchase_order.dart';
import '../repositories/dashboard_repository.dart';

class CreatePurchaseOrderUseCase {
  const CreatePurchaseOrderUseCase(this.repository);

  final DashboardRepository repository;

  Future<PurchaseOrder> call({
    required String vendor,
    required String itemName,
    required int quantity,
    required DateTime createdAt,
  }) {
    return repository.createPurchaseOrder(
      vendor: vendor,
      itemName: itemName,
      quantity: quantity,
      createdAt: createdAt,
    );
  }
}
