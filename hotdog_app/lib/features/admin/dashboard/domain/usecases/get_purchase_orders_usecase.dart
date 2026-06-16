import '../entities/purchase_order.dart';
import '../repositories/dashboard_repository.dart';

class GetPurchaseOrdersUseCase {
  const GetPurchaseOrdersUseCase(this.repository);
  final DashboardRepository repository;
  Future<List<PurchaseOrder>> call() => repository.getPurchaseOrders();
}
