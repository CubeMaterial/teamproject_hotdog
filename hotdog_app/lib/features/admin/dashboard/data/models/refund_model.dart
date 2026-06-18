import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/refund.dart';

class RefundModel extends Refund {
  const RefundModel({
    required super.id,
    required super.refundSeq,
    required super.buySeq,
    required super.userSeq,
    required super.orderNumber,
    required super.memberName,
    required super.itemName,
    required super.quantity,
    required super.amount,
    required super.orderedAt,
    required super.orderStatus,
    required super.rawStatus,
    required super.status,
    required super.requestedAt,
    required super.refundDetails,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: JsonReaders.stringValue(json, ['id', 'refund_seq']),
      refundSeq: JsonReaders.intValue(json, ['refundSeq', 'refund_seq']),
      buySeq: JsonReaders.intValue(json, ['buySeq', 'buy_seq']),
      userSeq: JsonReaders.intValue(json, ['userSeq', 'user_seq']),
      orderNumber: JsonReaders.stringValue(json, [
        'orderNumber',
        'buy_seq',
      ], fallback: 'SO-'),
      memberName: JsonReaders.stringValue(json, [
        'memberName',
        'user_name',
      ], fallback: '회원'),
      itemName: JsonReaders.stringValue(json, [
        'itemName',
        'product_name',
      ], fallback: '-'),
      quantity: JsonReaders.intValue(json, ['quantity', 'buy_qty']),
      amount: JsonReaders.intValue(json, ['amount', 'buy_price']),
      orderedAt: JsonReaders.dateTimeValue(json, ['orderedAt', 'buy_date']),
      orderStatus: JsonReaders.stringValue(json, [
        'orderStatus',
        'buy_status',
      ], fallback: '-'),
      rawStatus: JsonReaders.stringValue(json, [
        'rawStatus',
        'refund_state',
      ], fallback: '-'),
      status: JsonReaders.stringValue(json, ['status'], fallback: '환불신청'),
      requestedAt: JsonReaders.dateTimeValue(json, [
        'requestedAt',
        'refund_date',
      ]),
      refundDetails: JsonReaders.stringValue(json, [
        'refundDetails',
        'refund_details',
      ], fallback: ''),
    );
  }
}
