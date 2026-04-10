class AnalyticsSummary {
  final double totalSales;
  final double totalProfit;
  final int totalOrders;
  final int totalCustomers;
  final double totalReceivable;

  AnalyticsSummary({
    required this.totalSales,
    required this.totalProfit,
    required this.totalOrders,
    required this.totalCustomers,
    required this.totalReceivable,
  });

  factory AnalyticsSummary.empty() => AnalyticsSummary(
        totalSales: 0,
        totalProfit: 0,
        totalOrders: 0,
        totalCustomers: 0,
        totalReceivable: 0,
      );
}

class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint(this.label, this.value);
}

class PaymentMethodData {
  final String method;
  final double amount;
  final double percentage;

  PaymentMethodData({
    required this.method,
    required this.amount,
    required this.percentage,
  });
}

class CategorySalesData {
  final String category;
  final double sales;

  CategorySalesData(this.category, this.sales);
}
