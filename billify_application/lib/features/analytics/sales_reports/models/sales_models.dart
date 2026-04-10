

class SalesSummaryModel {
  final double totalSales;
  final int totalOrders;
  final double avgBillValue;
  final int totalItemsSold;

  SalesSummaryModel({
    required this.totalSales,
    required this.totalOrders,
    required this.avgBillValue,
    required this.totalItemsSold,
  });

  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      totalSales: double.tryParse(json['totalSales']?.toString() ?? '') ?? 0.0,
      totalOrders: int.tryParse(json['totalOrders']?.toString() ?? '') ?? 0,
      avgBillValue: double.tryParse(json['avgBillValue']?.toString() ?? '') ?? 0.0,
      totalItemsSold: int.tryParse(json['totalItemsSold']?.toString() ?? '') ?? 0,
    );
  }

  factory SalesSummaryModel.empty() => SalesSummaryModel(
    totalSales: 0,
    totalOrders: 0,
    avgBillValue: 0,
    totalItemsSold: 0,
  );
}

class SalesChartData {
  final DateTime date;
  final double amount;

  SalesChartData({required this.date, required this.amount});

  factory SalesChartData.fromJson(Map<String, dynamic> json) {
    return SalesChartData(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
    );
  }
}

class TopProductData {
  final String id;
  final String name;
  final int quantity;
  final double revenue;
  final double percentage;

  TopProductData({
    required this.id,
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.percentage,
  });

  factory TopProductData.fromJson(Map<String, dynamic> json) {
    return TopProductData(
      id: json['id']?.toString() ?? json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['product_name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      revenue: double.tryParse(json['revenue']?.toString() ?? '') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '') ?? 0.0,
    );
  }
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

  factory PaymentMethodData.fromJson(Map<String, dynamic> json) {
    return PaymentMethodData(
      method: json['method']?.toString() ?? json['payment_mode']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '') ?? 0.0,
    );
  }
}

class CategorySalesData {
  final String category;
  final double sales;
  final double percentage;

  CategorySalesData({
    required this.category,
    required this.sales,
    required this.percentage,
  });

  factory CategorySalesData.fromJson(Map<String, dynamic> json) {
    return CategorySalesData(
      category: json['category']?.toString() ?? '',
      sales: double.tryParse(json['sales']?.toString() ?? '') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '') ?? 0.0,
    );
  }
}
