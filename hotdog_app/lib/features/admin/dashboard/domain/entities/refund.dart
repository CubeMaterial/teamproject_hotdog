class Refund {
  const Refund({
    required this.id,
    required this.refundSeq,
    required this.buySeq,
    required this.userSeq,
    required this.orderNumber,
    required this.memberName,
    required this.itemName,
    required this.quantity,
    required this.amount,
    required this.orderedAt,
    required this.orderStatus,
    required this.rawStatus,
    required this.status,
    required this.requestedAt,
    required this.refundDetails,
  });

  final String id;
  final int refundSeq;
  final int buySeq;
  final int userSeq;
  final String orderNumber;
  final String memberName;
  final String itemName;
  final int quantity;
  final int amount;
  final DateTime orderedAt;
  final String orderStatus;
  final String rawStatus;
  final String status;
  final DateTime requestedAt;
  final String refundDetails;
}
