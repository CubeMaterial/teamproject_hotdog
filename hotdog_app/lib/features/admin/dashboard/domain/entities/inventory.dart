class Inventory {
  const Inventory({
    required this.inventorySeq,
    required this.inventorySerialNumber,
  });

  final String inventorySeq;
  final String inventorySerialNumber;
}

class InventoryItem extends Inventory {
  const InventoryItem({
    required super.inventorySeq,
    required super.inventorySerialNumber,
    required this.categorySeq,
    required this.name,
    required this.category,
    required this.stock,
    required this.safeStock,
    required this.status,
    this.forecastBaseDate,
    this.forecastDate7d,
    this.forecastDate30d,
    this.predictedDemand7d,
    this.predictedStockAfter7d,
    this.stockRisk7d,
    this.predictedDemand30d,
    this.predictedStockAfter30d,
    this.stockRisk30d,
  });

  String get id => inventorySeq;

  bool get hasForecast =>
      predictedStockAfter7d != null || predictedStockAfter30d != null;

  String get forecastRiskLabel {
    final risks = {stockRisk7d, stockRisk30d};
    if (risks.contains('HIGH')) {
      return '위험';
    }
    if (risks.contains('WATCH')) {
      return '주의';
    }
    if (risks.contains('OK')) {
      return '양호';
    }
    return '-';
  }

  final int categorySeq;
  final String name;
  final String category;
  final int stock;
  final int safeStock;
  final String status;
  final String? forecastBaseDate;
  final String? forecastDate7d;
  final String? forecastDate30d;
  final double? predictedDemand7d;
  final double? predictedStockAfter7d;
  final String? stockRisk7d;
  final double? predictedDemand30d;
  final double? predictedStockAfter30d;
  final String? stockRisk30d;
}

class StockHistory {
  const StockHistory({
    required this.id,
    required this.productSeq,
    required this.itemName,
    required this.category,
    required this.type,
    required this.quantity,
    required this.status,
    required this.happenedAt,
  });

  final String id;
  final String productSeq;
  final String itemName;
  final String category;
  final String type;
  final int quantity;
  final String status;
  final DateTime happenedAt;
}
