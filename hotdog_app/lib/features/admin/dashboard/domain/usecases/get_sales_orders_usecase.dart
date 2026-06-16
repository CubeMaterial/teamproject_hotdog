import '../entities/sales_order.dart';
import '../repositories/dashboard_repository.dart';

class GetSalesOrdersUseCase {
  const GetSalesOrdersUseCase(this.repository);
  final DashboardRepository repository;
  Future<List<SalesOrder>> call() => repository.getSalesOrders();
}
