import 'package:flutter/foundation.dart';

import '../../domain/entities/purchase_order.dart';
import '../../domain/usecases/get_purchase_orders_usecase.dart';

class PurchaseOrderViewModel extends ChangeNotifier {
  PurchaseOrderViewModel(this._getPurchaseOrdersUseCase);
  final GetPurchaseOrdersUseCase _getPurchaseOrdersUseCase;
  List<PurchaseOrder> orders = [];
  Future<void> load() async {
    orders = await _getPurchaseOrdersUseCase();
    notifyListeners();
  }
}
