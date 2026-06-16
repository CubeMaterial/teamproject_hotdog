import 'package:flutter/foundation.dart';

import '../../domain/entities/sales_order.dart';
import '../../domain/usecases/get_sales_orders_usecase.dart';

class SalesOrderViewModel extends ChangeNotifier {
  SalesOrderViewModel(this._getSalesOrdersUseCase);
  final GetSalesOrdersUseCase _getSalesOrdersUseCase;
  List<SalesOrder> orders = [];
  Future<void> load() async {
    orders = await _getSalesOrdersUseCase();
    notifyListeners();
  }
}
