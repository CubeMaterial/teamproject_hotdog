import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/inventory.dart';

class InventoryModel extends InventoryItem {
  const InventoryModel({
    required super.inventorySeq,
    required super.inventorySerialNumber,
    required super.categorySeq,
    required super.name,
    required super.category,
    required super.stock,
    required super.safeStock,
    required super.status,
    super.forecastBaseDate,
    super.forecastDate7d,
    super.forecastDate30d,
    super.predictedDemand7d,
    super.predictedStockAfter7d,
    super.stockRisk7d,
    super.predictedDemand30d,
    super.predictedStockAfter30d,
    super.stockRisk30d,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    final stock = JsonReaders.intValue(json, ['stock', 'product_qty']);

    return InventoryModel(
      inventorySeq: JsonReaders.stringValue(json, [
        'inventorySeq',
        'inventory_seq',
        'productSeq',
        'product_seq',
      ]),
      inventorySerialNumber: JsonReaders.stringValue(json, [
        'inventorySerialNumber',
        'inventory_serial_number',
        'productSeq',
        'product_seq',
      ]),
      categorySeq: JsonReaders.intValue(json, [
        'productCategorySeq',
        'product_category_seq',
        'productSubCategorySeq',
        'product_sub_category_seq',
      ]),
      name: JsonReaders.stringValue(json, ['name', 'product_name']),
      category: JsonReaders.stringValue(json, [
        'category',
        'product_category_name',
        'product_sub_category_name',
      ], fallback: '미분류'),
      stock: stock,
      safeStock: JsonReaders.intValue(json, [
        'safeStock',
        'safe_stock',
      ], fallback: 10),
      status: JsonReaders.stringValue(json, [
        'status',
      ], fallback: _statusForStock(stock)),
      forecastBaseDate: _nullableString(json, [
        'forecastBaseDate',
        'forecast_base_date',
      ]),
      forecastDate7d: _nullableString(json, [
        'forecastDate7d',
        'forecast_date_7d',
      ]),
      forecastDate30d: _nullableString(json, [
        'forecastDate30d',
        'forecast_date_30d',
      ]),
      predictedDemand7d: _nullableDouble(json, [
        'predictedDemand7d',
        'predicted_demand_7d',
      ]),
      predictedStockAfter7d: _nullableDouble(json, [
        'predictedStockAfter7d',
        'predicted_stock_after_7d',
      ]),
      stockRisk7d: _nullableString(json, ['stockRisk7d', 'stock_risk_7d']),
      predictedDemand30d: _nullableDouble(json, [
        'predictedDemand30d',
        'predicted_demand_30d',
      ]),
      predictedStockAfter30d: _nullableDouble(json, [
        'predictedStockAfter30d',
        'predicted_stock_after_30d',
      ]),
      stockRisk30d: _nullableString(json, ['stockRisk30d', 'stock_risk_30d']),
    );
  }

  static String _statusForStock(int stock) {
    if (stock <= 10) {
      return '부족';
    }
    if (stock <= 30) {
      return '주의';
    }
    if (stock > 50) {
      return '정상';
    }
    return '보통';
  }

  static String? _nullableString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      final text = '$value'.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static double? _nullableDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse('$value');
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }
}

class StockHistoryModel extends StockHistory {
  const StockHistoryModel({
    required super.id,
    required super.productSeq,
    required super.itemName,
    required super.category,
    required super.type,
    required super.quantity,
    required super.status,
    required super.happenedAt,
  });

  factory StockHistoryModel.fromJson(Map<String, dynamic> json) {
    return StockHistoryModel(
      id: JsonReaders.stringValue(json, ['id']),
      productSeq: JsonReaders.stringValue(json, ['productSeq', 'product_seq']),
      itemName: JsonReaders.stringValue(json, ['itemName', 'product_name']),
      category: JsonReaders.stringValue(json, [
        'category',
        'product_category_name',
        'product_sub_category_name',
      ], fallback: '미분류'),
      type: JsonReaders.stringValue(json, ['type'], fallback: '입고'),
      quantity: JsonReaders.intValue(json, ['quantity', 'qty']),
      status: JsonReaders.stringValue(json, ['status'], fallback: '처리완료'),
      happenedAt: JsonReaders.dateTimeValue(json, [
        'happenedAt',
        'happened_at',
      ]),
    );
  }
}
