class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.orderNumber,
    required this.itemName,
    required this.memberName,
    required this.totalPrice,
    required this.status,
    required this.orderedAt,
  });

  final String id;
  final String orderNumber;
  final String itemName;
  final String memberName;
  final int totalPrice;
  final String status;
  final DateTime orderedAt;
}
