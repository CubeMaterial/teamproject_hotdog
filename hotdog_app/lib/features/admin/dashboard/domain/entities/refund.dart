class Refund {
  const Refund({
    required this.id,
    required this.orderNumber,
    required this.memberName,
    required this.amount,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String orderNumber;
  final String memberName;
  final int amount;
  final String status;
  final DateTime requestedAt;
}
