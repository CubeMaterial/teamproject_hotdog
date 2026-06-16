import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/purchase_order.dart';

class PurchaseOrderModel extends PurchaseOrder {
  const PurchaseOrderModel({
    required super.id,
    required super.vendor,
    required super.itemName,
    required super.quantity,
    required super.status,
    required super.createdAt,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: JsonReaders.stringValue(json, ['id', 'order_seq']),
      vendor: JsonReaders.stringValue(json, [
        'vendor',
        'maker_name',
      ], fallback: '미지정'),
      itemName: JsonReaders.stringValue(json, ['itemName', 'product_name']),
      quantity: JsonReaders.intValue(json, ['quantity', 'order_qty']),
      status: JsonReaders.stringValue(json, ['status'], fallback: '발주'),
      createdAt: JsonReaders.dateTimeValue(json, ['createdAt', 'order_date']),
    );
  }
}
