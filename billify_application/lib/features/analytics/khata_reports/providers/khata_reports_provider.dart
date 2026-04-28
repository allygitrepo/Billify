import 'package:billify/features/analytics/khata_reports/models/khata_report_model.dart';
import 'package:billify/features/analytics/khata_reports/services/khata_reports_service.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class KhataReportsState {
  final KhataSummaryModel summary;
  final List<KhataDueReportItem> dueList;
  final List<KhataDueReportItem> topDueCustomers;
  final KhataPaymentTrend paymentTrends;
  final List<KhataChartPoint> creditSales;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? branchId;
  final String searchQuery;

  KhataReportsState({
    required this.summary,
    required this.dueList,
    required this.topDueCustomers,
    required this.paymentTrends,
    required this.creditSales,
    required this.isLoading,
    this.error,
    this.startDate,
    this.endDate,
    this.branchId,
    this.searchQuery = '',
  });

  KhataReportsState copyWith({
    KhataSummaryModel? summary,
    List<KhataDueReportItem>? dueList,
    List<KhataDueReportItem>? topDueCustomers,
    KhataPaymentTrend? paymentTrends,
    List<KhataChartPoint>? creditSales,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? searchQuery,
  }) {
    return KhataReportsState(
      summary: summary ?? this.summary,
      dueList: dueList ?? this.dueList,
      topDueCustomers: topDueCustomers ?? this.topDueCustomers,
      paymentTrends: paymentTrends ?? this.paymentTrends,
      creditSales: creditSales ?? this.creditSales,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      branchId: branchId ?? this.branchId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  factory KhataReportsState.initial() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return KhataReportsState(
      summary: KhataSummaryModel.empty(),
      dueList: [],
      topDueCustomers: [],
      paymentTrends: KhataPaymentTrend(trend: [], totalPaid: 0, totalDue: 0),
      creditSales: [],
      isLoading: false,
      startDate: DateTime(
        thirtyDaysAgo.year,
        thirtyDaysAgo.month,
        thirtyDaysAgo.day,
      ),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  List<KhataDueReportItem> get filteredDueList {
    if (searchQuery.isEmpty) return dueList;
    return dueList
        .where(
          (item) =>
              item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.phoneNumber.contains(searchQuery),
        )
        .toList();
  }
}

final khataReportsProvider =
    StateNotifierProvider<KhataReportsNotifier, KhataReportsState>((ref) {
      final service = ref.watch(khataReportsServiceProvider);
      final businessId =
          ref.watch(businessProvider).currentBusinessId ?? 'default';
      return KhataReportsNotifier(service, businessId);
    });

class KhataReportsNotifier extends StateNotifier<KhataReportsState> {
  final KhataReportsService _service;
  final String _businessId;

  KhataReportsNotifier(this._service, this._businessId)
    : super(KhataReportsState.initial()) {
    refresh();
  }

  Future<void> refresh() async {
    await fetchAllData();
  }

  void updateFilters({DateTime? start, DateTime? end, String? branch}) {
    state = state.copyWith(
      startDate: start != null
          ? DateTime(start.year, start.month, start.day)
          : state.startDate,
      endDate: end != null
          ? DateTime(end.year, end.month, end.day, 23, 59, 59)
          : state.endDate,
      branchId: branch ?? state.branchId,
    );
    fetchAllData();
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> fetchAllData() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _service.getSummary(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getDueReport(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getTopDueCustomers(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getPaymentTrends(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getCreditSales(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
      ]);

      state = state.copyWith(
        summary: results[0] as KhataSummaryModel,
        dueList: results[1] as List<KhataDueReportItem>,
        topDueCustomers: results[2] as List<KhataDueReportItem>,
        paymentTrends: results[3] as KhataPaymentTrend,
        creditSales: results[4] as List<KhataChartPoint>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMoreDueItems({int page = 1}) async {
    try {
      final moreItems = await _service.getDueReport(
        _businessId,
        startDate: state.startDate,
        endDate: state.endDate,
        branchId: state.branchId,
        page: page,
      );
      if (page == 1) {
        state = state.copyWith(dueList: moreItems);
      } else {
        state = state.copyWith(dueList: [...state.dueList, ...moreItems]);
      }
    } catch (e) {
      print("Error fetching more due items: $e");
    }
  }
}
