import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/sales_order.dart';

class SalesOrderModel extends SalesOrder {
  const SalesOrderModel({
    required super.id,
    required super.orderNumber,
    required super.itemName,
    required super.memberName,
    required super.totalPrice,
    required super.status,
    required super.orderedAt,
  });

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      id: JsonReaders.stringValue(json, ['id', 'buy_seq']),
      orderNumber: JsonReaders.stringValue(json, [
        'orderNumber',
      ], fallback: 'SO-'),
      itemName: JsonReaders.stringValue(json, ['itemName', 'product_name']),
      memberName: JsonReaders.stringValue(json, [
        'memberName',
        'user_name',
      ], fallback: '회원'),
      totalPrice: JsonReaders.intValue(json, ['totalPrice', 'buy_price']),
      status: JsonReaders.stringValue(json, ['status'], fallback: '결제완료'),
      orderedAt: JsonReaders.dateTimeValue(json, ['orderedAt', 'buy_date']),
    );
  }
}
