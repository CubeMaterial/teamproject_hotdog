import 'package:flutter/foundation.dart';

import '../../domain/entities/purchase_order.dart';
import '../../domain/usecases/create_purchase_order_usecase.dart';
import '../../domain/usecases/get_purchase_orders_usecase.dart';

class PurchaseOrderViewModel extends ChangeNotifier {
  PurchaseOrderViewModel(
    this._getPurchaseOrdersUseCase,
    this._createPurchaseOrderUseCase,
  );

  final GetPurchaseOrdersUseCase _getPurchaseOrdersUseCase;
  final CreatePurchaseOrderUseCase _createPurchaseOrderUseCase;

  List<PurchaseOrder> orders = [];

  Future<void> load() async {
    orders = await _getPurchaseOrdersUseCase();
    notifyListeners();
  }

  Future<void> createOrder({
    required String vendor,
    required String itemName,
    required int quantity,
    required DateTime createdAt,
  }) async {
    await _createPurchaseOrderUseCase(
      vendor: vendor,
      itemName: itemName,
      quantity: quantity,
      createdAt: createdAt,
    );
    await load();
  }
}
