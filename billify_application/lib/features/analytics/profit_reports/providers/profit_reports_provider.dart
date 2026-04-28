import 'package:billify/features/analytics/profit_reports/models/profit_report_model.dart';
import 'package:billify/features/analytics/profit_reports/services/profit_reports_service.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ProfitReportsState {
  final ProfitSummaryModel summary;
  final List<ProfitChartData> trend;
  final List<ProductProfitData> topProducts;
  final List<CategoryProfitData> categorySales;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? branchId;

  ProfitReportsState({
    required this.summary,
    required this.trend,
    required this.topProducts,
    required this.categorySales,
    required this.isLoading,
    this.error,
    this.startDate,
    this.endDate,
    this.branchId,
  });

  ProfitReportsState copyWith({
    ProfitSummaryModel? summary,
    List<ProfitChartData>? trend,
    List<ProductProfitData>? topProducts,
    List<CategoryProfitData>? categorySales,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) {
    return ProfitReportsState(
      summary: summary ?? this.summary,
      trend: trend ?? this.trend,
      topProducts: topProducts ?? this.topProducts,
      categorySales: categorySales ?? this.categorySales,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      branchId: branchId ?? this.branchId,
    );
  }

  factory ProfitReportsState.initial() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return ProfitReportsState(
      summary: ProfitSummaryModel.empty(),
      trend: [],
      topProducts: [],
      categorySales: [],
      isLoading: false,
      startDate: DateTime(
        thirtyDaysAgo.year,
        thirtyDaysAgo.month,
        thirtyDaysAgo.day,
      ),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }
}

final profitReportsProvider =
    StateNotifierProvider<ProfitReportsNotifier, ProfitReportsState>((ref) {
      final service = ref.watch(profitReportsServiceProvider);
      final businessId =
          ref.watch(businessProvider).currentBusinessId ?? 'default';
      return ProfitReportsNotifier(service, businessId);
    });

class ProfitReportsNotifier extends StateNotifier<ProfitReportsState> {
  final ProfitReportsService _service;
  final String _businessId;

  ProfitReportsNotifier(this._service, this._businessId)
    : super(ProfitReportsState.initial()) {
    refresh();
  }

  Future<void> refresh() async {
    await fetchAllData();
  }

  void updateFilters({DateTime? start, DateTime? end, String? branch}) {
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _service.getProfitSummary(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getProfitTrend(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getProfitByProducts(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _service.getProfitByCategories(
          _businessId,
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
      ]);

      state = state.copyWith(
        summary: results[0] as ProfitSummaryModel,
        trend: results[1] as List<ProfitChartData>,
        topProducts: results[2] as List<ProductProfitData>,
        categorySales: results[3] as List<CategoryProfitData>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
