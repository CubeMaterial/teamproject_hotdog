class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.vendor,
    required this.itemName,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String vendor;
  final String itemName;
  final int quantity;
  final String status;
  final DateTime createdAt;
}
