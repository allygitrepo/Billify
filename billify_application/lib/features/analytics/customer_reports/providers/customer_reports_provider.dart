import 'package:billify/features/analytics/customer_reports/models/customer_report_model.dart';
import 'package:billify/features/analytics/customer_reports/services/customer_reports_service.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final customerReportsProvider =
    StateNotifierProvider<CustomerReportsNotifier, CustomerReportsState>((ref) {
      final service = ref.watch(customerReportsServiceProvider);
      final businessId =
          ref.watch(businessProvider).currentBusinessId ?? 'default';
      return CustomerReportsNotifier(service, businessId);
    });

class CustomerReportsNotifier extends StateNotifier<CustomerReportsState> {
  final CustomerReportsService _service;
  final String _businessId;

  CustomerReportsNotifier(this._service, this._businessId)
    : super(
        CustomerReportsState(
          summary: CustomerReportSummary(
            totalCustomers: 0,
            totalReceivable: 0,
            totalPayable: 0,
            netBalance: 0,
          ),
          customers: [],
          isLoading: true,
        ),
      ) {
    fetchData();
  }

  Future<void> fetchData({String? search}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _service.fetchCustomerAnalytics(
        _businessId,
        search: search,
      );

      final summary = CustomerReportSummary.fromJson(result['summary']);
      final customers = (result['customers'] as List)
          .map((item) => CustomerReportItem.fromJson(item))
          .toList();

      state = state.copyWith(
        summary: summary,
        customers: customers,
        isLoading: false,
        searchQuery: search ?? '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateSearch(String query) {
    fetchData(search: query);
  }

  void refresh() {
    fetchData(search: state.searchQuery.isEmpty ? null : state.searchQuery);
  }
}
