class KhataSummaryModel {
  final double totalReceivable;
  final double totalReceived;
  final double totalCreditSales;
  final int customersWithDue;
  final double avgDueAmount;

  KhataSummaryModel({
    required this.totalReceivable,
    required this.totalReceived,
    required this.totalCreditSales,
    required this.customersWithDue,
    required this.avgDueAmount,
  });

  factory KhataSummaryModel.fromJson(Map<String, dynamic> json) {
    return KhataSummaryModel(
      totalReceivable: double.tryParse(json['totalReceivable']?.toString() ?? '') ?? 0.0,
      totalReceived: double.tryParse(json['totalReceived']?.toString() ?? '') ?? 0.0,
      totalCreditSales: double.tryParse(json['totalCreditSales']?.toString() ?? '') ?? 0.0,
      customersWithDue: int.tryParse(json['customersWithDue']?.toString() ?? '') ?? 0,
      avgDueAmount: double.tryParse(json['avgDueAmount']?.toString() ?? '') ?? 0.0,
    );
  }

  factory KhataSummaryModel.empty() => KhataSummaryModel(
    totalReceivable: 0.0,
    totalReceived: 0.0,
    totalCreditSales: 0.0,
    customersWithDue: 0,
    avgDueAmount: 0.0,
  );
}

class KhataDueReportItem {
  final String customerId;
  final String name;
  final String phoneNumber;
  final double totalDue;
  final DateTime? lastPaymentDate;
  final double? creditLimit;

  KhataDueReportItem({
    required this.customerId,
    required this.name,
    required this.phoneNumber,
    required this.totalDue,
    this.lastPaymentDate,
    this.creditLimit,
  });

  factory KhataDueReportItem.fromJson(Map<String, dynamic> json) {
    return KhataDueReportItem(
      customerId: json['customer_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone']?.toString() ?? '',
      totalDue: double.tryParse(json['total_due']?.toString() ?? '') ?? 0.0,
      lastPaymentDate: json['last_payment_date'] != null 
          ? DateTime.tryParse(json['last_payment_date'].toString()) 
          : null,
      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? ''),
    );
  }
}

class KhataChartPoint {
  final DateTime date;
  final double value;

  KhataChartPoint({required this.date, required this.value});

  factory KhataChartPoint.fromJson(Map<String, dynamic> json) {
    return KhataChartPoint(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      value: double.tryParse(json['value']?.toString() ?? '') ?? 0.0,
    );
  }
}

class KhataPaymentTrend {
  final List<KhataChartPoint> trend;
  final double totalPaid;
  final double totalDue;

  KhataPaymentTrend({
    required this.trend,
    required this.totalPaid,
    required this.totalDue,
  });

  factory KhataPaymentTrend.fromJson(Map<String, dynamic> json) {
    final trendData = json['trend'] as List? ?? [];
    return KhataPaymentTrend(
      trend: trendData.map((e) => KhataChartPoint.fromJson(e)).toList(),
      totalPaid: double.tryParse(json['totalPaid']?.toString() ?? '') ?? 0.0,
      totalDue: double.tryParse(json['totalDue']?.toString() ?? '') ?? 0.0,
    );
  }
}
