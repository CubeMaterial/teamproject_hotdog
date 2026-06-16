class DashboardSummary {
  const DashboardSummary({
    required this.todaySales,
    required this.monthSales,
    required this.weeklySales,
    required this.refundCount,
    required this.todayPostCount,
    required this.topSellingProducts,
  });

  final int todaySales;
  final int monthSales;
  final List<int> weeklySales;
  final int refundCount;
  final int todayPostCount;
  final List<TopSellingProduct> topSellingProducts;
}

class TopSellingProduct {
  const TopSellingProduct({
    required this.name,
    required this.quantity,
    required this.salesAmount,
  });

  final String name;
  final int quantity;
  final int salesAmount;
}
