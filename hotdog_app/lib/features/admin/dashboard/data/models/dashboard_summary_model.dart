import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.todaySales,
    required super.monthSales,
    required super.weeklySales,
    required super.refundCount,
    required super.todayPostCount,
    required super.topSellingProducts,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final weeklySales = json['weeklySales'];
    final products = json['topSellingProducts'];

    return DashboardSummaryModel(
      todaySales: JsonReaders.intValue(json, ['todaySales']),
      monthSales: JsonReaders.intValue(json, ['monthSales']),
      weeklySales: weeklySales is List
          ? weeklySales
                .map((value) => JsonReaders.intValue({'v': value}, ['v']))
                .map((value) => value < 0 ? 0 : value)
                .toList()
          : const [0, 0, 0, 0, 0, 0],
      refundCount: JsonReaders.intValue(json, ['refundCount']),
      todayPostCount: JsonReaders.intValue(json, ['todayPostCount']),
      topSellingProducts: products is List
          ? products
                .whereType<Map>()
                .map((json) => TopSellingProductModel.fromJson(json.cast()))
                .toList()
          : const [],
    );
  }

  factory DashboardSummaryModel.empty() {
    return const DashboardSummaryModel(
      todaySales: 0,
      monthSales: 0,
      weeklySales: [0, 0, 0, 0, 0, 0],
      refundCount: 0,
      todayPostCount: 0,
      topSellingProducts: [],
    );
  }
}

class TopSellingProductModel extends TopSellingProduct {
  const TopSellingProductModel({
    required super.name,
    required super.quantity,
    required super.salesAmount,
  });

  factory TopSellingProductModel.fromJson(Map<String, dynamic> json) {
    return TopSellingProductModel(
      name: JsonReaders.stringValue(json, ['name', 'product_name']),
      quantity: JsonReaders.intValue(json, ['quantity']),
      salesAmount: JsonReaders.intValue(json, ['salesAmount']),
    );
  }
}
