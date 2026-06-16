import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/refund.dart';

class RefundModel extends Refund {
  const RefundModel({
    required super.id,
    required super.orderNumber,
    required super.memberName,
    required super.amount,
    required super.status,
    required super.requestedAt,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: JsonReaders.stringValue(json, ['id', 'refund_seq']),
      orderNumber: JsonReaders.stringValue(json, [
        'orderNumber',
        'buy_seq',
      ], fallback: 'SO-'),
      memberName: JsonReaders.stringValue(json, [
        'memberName',
        'user_name',
      ], fallback: '회원'),
      amount: JsonReaders.intValue(json, ['amount', 'buy_price']),
      status: JsonReaders.stringValue(json, ['status'], fallback: '대기'),
      requestedAt: JsonReaders.dateTimeValue(json, [
        'requestedAt',
        'refund_date',
      ]),
    );
  }
}
