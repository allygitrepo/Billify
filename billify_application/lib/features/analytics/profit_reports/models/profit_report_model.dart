class ProfitSummaryModel {
  final double totalProfit;
  final double totalRevenue;
  final double totalCost;
  final double profitMargin;
  final int totalOrders;

  ProfitSummaryModel({
    required this.totalProfit,
    required this.totalRevenue,
    required this.totalCost,
    required this.profitMargin,
    required this.totalOrders,
  });

  factory ProfitSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProfitSummaryModel(
      totalProfit: double.tryParse(json['totalProfit']?.toString() ?? '') ?? 0.0,
      totalRevenue: double.tryParse(json['totalRevenue']?.toString() ?? '') ?? 0.0,
      totalCost: double.tryParse(json['totalCost']?.toString() ?? '') ?? 0.0,
      profitMargin: double.tryParse(json['profitMargin']?.toString() ?? '') ?? 0.0,
      totalOrders: int.tryParse(json['totalOrders']?.toString() ?? '') ?? 0,
    );
  }

  factory ProfitSummaryModel.empty() => ProfitSummaryModel(
    totalProfit: 0.0,
    totalRevenue: 0.0,
    totalCost: 0.0,
    profitMargin: 0.0,
    totalOrders: 0,
  );
}

class ProfitChartData {
  final DateTime date;
  final double profit;

  ProfitChartData({required this.date, required this.profit});

  factory ProfitChartData.fromJson(Map<String, dynamic> json) {
    return ProfitChartData(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      profit: double.tryParse(json['profit']?.toString() ?? '') ?? 0.0,
    );
  }
}

class ProductProfitData {
  final String id;
  final String name;
  final int quantity;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;

  ProductProfitData({
    required this.id,
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
  });

  factory ProductProfitData.fromJson(Map<String, dynamic> json) {
    return ProductProfitData(
      id: json['id']?.toString() ?? json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['product_name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      revenue: double.tryParse(json['revenue']?.toString() ?? '') ?? 0.0,
      cost: double.tryParse(json['cost']?.toString() ?? '') ?? 0.0,
      profit: double.tryParse(json['profit']?.toString() ?? '') ?? 0.0,
      margin: double.tryParse(json['margin']?.toString() ?? '') ?? 0.0,
    );
  }
}

class CategoryProfitData {
  final String category;
  final double profit;
  final double margin;

  CategoryProfitData({
    required this.category,
    required this.profit,
    required this.margin,
  });

  factory CategoryProfitData.fromJson(Map<String, dynamic> json) {
    return CategoryProfitData(
      category: json['category']?.toString() ?? '',
      profit: double.tryParse(json['profit']?.toString() ?? '') ?? 0.0,
      margin: double.tryParse(json['margin']?.toString() ?? '') ?? 0.0,
    );
  }
}
