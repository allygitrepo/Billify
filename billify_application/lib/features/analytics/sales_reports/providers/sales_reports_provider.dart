import 'package:billify/data/models/invoice_model.dart';
import 'package:billify/features/analytics/sales_reports/models/sales_models.dart';
import 'package:billify/features/analytics/sales_reports/services/sales_reports_service.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class SalesReportsState {
  final SalesSummaryModel summary;
  final List<SalesChartData> trend;
  final List<TopProductData> topProducts;
  final List<CategorySalesData> categorySales;
  final List<PaymentMethodData> paymentMethods;
  final List<InvoiceModel> invoices;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? branchId;

  SalesReportsState({
    required this.summary,
    required this.trend,
    required this.topProducts,
    required this.categorySales,
    required this.paymentMethods,
    required this.invoices,
    required this.isLoading,
    this.error,
    this.startDate,
    this.endDate,
    this.branchId,
  });

  SalesReportsState copyWith({
    SalesSummaryModel? summary,
    List<SalesChartData>? trend,
    List<TopProductData>? topProducts,
    List<CategorySalesData>? categorySales,
    List<PaymentMethodData>? paymentMethods,
    List<InvoiceModel>? invoices,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) {
    return SalesReportsState(
      summary: summary ?? this.summary,
      trend: trend ?? this.trend,
      topProducts: topProducts ?? this.topProducts,
      categorySales: categorySales ?? this.categorySales,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      branchId: branchId ?? this.branchId,
    );
  }

  factory SalesReportsState.initial() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return SalesReportsState(
      summary: SalesSummaryModel.empty(),
      trend: [],
      topProducts: [],
      categorySales: [],
      paymentMethods: [],
      invoices: [],
      isLoading: false,
      startDate: DateTime(
        thirtyDaysAgo.year,
        thirtyDaysAgo.month,
        thirtyDaysAgo.day,
      ), // Start of 30 days ago
      endDate: DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ), // End of today
    );
  }
}

final salesReportsProvider =
    StateNotifierProvider<SalesReportsNotifier, SalesReportsState>((ref) {
      final service = ref.watch(salesReportsServiceProvider);
      final businessId =
          ref.watch(businessProvider).currentBusinessId ?? 'default';
      return SalesReportsNotifier(service, businessId);
    });

class SalesReportsNotifier extends StateNotifier<SalesReportsState> {
  final SalesReportsService _service;
  final String _businessId;

  SalesReportsNotifier(this._service, this._businessId)
    : super(SalesReportsState.initial()) {
    refresh();
  }

  Future<void> refresh() async {
    await fetchAllData();
  }

  void updateFilters({DateTime? start, DateTime? end, String? branch}) {
    // Normalize start to 00:00 and end to 23:59
    DateTime? normalizedStart;
    if (start != null) {
      normalizedStart = DateTime(start.year, start.month, start.day);
    }

    DateTime? normalizedEnd;
    if (end != null) {
      normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    }

    state = state.copyWith(
      startDate: normalizedStart ?? state.startDate,
      endDate: normalizedEnd ?? state.endDate,
      branchId: branch ?? state.branchId,
    );
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    if (state.isLoading) return;
    
    // Check if business ID is temporary
    if (int.tryParse(_businessId) == null) {
      state = state.copyWith(
        isLoading: false, 
        error: "Business data is being synchronized. Please wait...",
        summary: SalesSummaryModel.empty(),
        trend: [],
        topProducts: [],
        categorySales: [],
        paymentMethods: [],
        invoices: [],
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final summaryList = await Future.wait([
        _service.getSalesSummary(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getSalesTrend(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getTopProducts(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getCategorySales(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getPaymentSummary(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getSalesList(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
          page: 1,
        ),
      ]);

      state = state.copyWith(
        summary: summaryList[0] as SalesSummaryModel,
        trend: summaryList[1] as List<SalesChartData>,
        topProducts: summaryList[2] as List<TopProductData>,
        categorySales: summaryList[3] as List<CategorySalesData>,
        paymentMethods: summaryList[4] as List<PaymentMethodData>,
        invoices: summaryList[5] as List<InvoiceModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Methods for individual fetching if needed later
  Future<void> fetchInvoices({int page = 1}) async {
    try {
      final list = await _service.getSalesList(
        _businessId,
        startDate: state.startDate,
        endDate: state.endDate,
        branchId: state.branchId,
        page: page,
      );
      if (page == 1) {
        state = state.copyWith(invoices: list);
      } else {
        state = state.copyWith(invoices: [...state.invoices, ...list]);
      }
    } catch (e) {
      print("Error fetching invoices: $e");
    }
  }
}
