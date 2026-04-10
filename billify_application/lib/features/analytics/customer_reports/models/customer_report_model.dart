class CustomerReportSummary {
  final int totalCustomers;
  final double totalReceivable;
  final double totalPayable;
  final double netBalance;

  CustomerReportSummary({
    required this.totalCustomers,
    required this.totalReceivable,
    required this.totalPayable,
    required this.netBalance,
  });

  factory CustomerReportSummary.fromJson(Map<String, dynamic> json) {
    return CustomerReportSummary(
      totalCustomers: json['totalCustomers'] ?? 0,
      totalReceivable: double.tryParse(json['totalReceivable'].toString()) ?? 0.0,
      totalPayable: double.tryParse(json['totalPayable'].toString()) ?? 0.0,
      netBalance: double.tryParse(json['netBalance'].toString()) ?? 0.0,
    );
  }
}

class CustomerReportItem {
  final int id;
  final String name;
  final String phoneNumber;
  final String? city;
  final double openingBalance;
  final double totalBilled;
  final double totalPaid;
  final double remainingBalance;
  final DateTime? lastActivity;

  CustomerReportItem({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.city,
    required this.openingBalance,
    required this.totalBilled,
    required this.totalPaid,
    required this.remainingBalance,
    this.lastActivity,
  });

  factory CustomerReportItem.fromJson(Map<String, dynamic> json) {
    return CustomerReportItem(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      phoneNumber: json['phoneNumber'] ?? '',
      city: json['city'],
      openingBalance: double.tryParse(json['openingBalance'].toString()) ?? 0.0,
      totalBilled: double.tryParse(json['totalBilled'].toString()) ?? 0.0,
      totalPaid: double.tryParse(json['totalPaid'].toString()) ?? 0.0,
      remainingBalance: double.tryParse(json['remainingBalance'].toString()) ?? 0.0,
      lastActivity: json['lastActivity'] != null ? DateTime.parse(json['lastActivity']) : null,
    );
  }
}

class CustomerReportsState {
  final CustomerReportSummary summary;
  final List<CustomerReportItem> customers;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  CustomerReportsState({
    required this.summary,
    required this.customers,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  CustomerReportsState copyWith({
    CustomerReportSummary? summary,
    List<CustomerReportItem>? customers,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return CustomerReportsState(
      summary: summary ?? this.summary,
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
