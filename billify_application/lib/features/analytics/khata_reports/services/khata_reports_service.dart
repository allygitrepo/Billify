import 'package:billify/core/constants/api_endpoints.dart';
import 'package:billify/core/services/api_service.dart';
import 'package:billify/features/analytics/khata_reports/models/khata_report_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final khataReportsServiceProvider = Provider<KhataReportsService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return KhataReportsService(apiService);
});

class KhataReportsService {
  final ApiService _apiService;

  KhataReportsService(this._apiService);

  Map<String, dynamic> _buildParams(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) {
    return {
      'business_id': businessId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (branchId != null) 'branch_id': branchId,
    };
  }

  Future<KhataSummaryModel> getSummary(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    final uri = ApiEndpoints.getKhataSummary(businessId);
    print("Fetching Khata Summary from: $uri");
    final response = await _apiService.get(
      uri,
      queryParameters: _buildParams(
        businessId,
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      return KhataSummaryModel.fromJson(response.data['summary']);
    }
    return KhataSummaryModel.empty();
  }

  Future<List<KhataDueReportItem>> getDueReport(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    int page = 1,
  }) async {
    final params = _buildParams(
      businessId,
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
    );
    params['page'] = page;
    final response = await _apiService.get(
      ApiEndpoints.getKhataDueReport(businessId),
      queryParameters: params,
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['report'] as List? ?? [];
      return data.map((e) => KhataDueReportItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<KhataPaymentTrend> getPaymentTrends(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.getKhataPayments(businessId),
      queryParameters: _buildParams(
        businessId,
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      return KhataPaymentTrend.fromJson(response.data['payments']);
    }
    return KhataPaymentTrend(trend: [], totalPaid: 0, totalDue: 0);
  }

  Future<List<KhataChartPoint>> getCreditSales(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.getKhataCreditReport(businessId),
      queryParameters: _buildParams(
        businessId,
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['credit'] as List? ?? [];
      return data.map((e) => KhataChartPoint.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<KhataDueReportItem>> getTopDueCustomers(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.getKhataCustomersAnalytics(businessId),
      queryParameters: _buildParams(
        businessId,
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['top_due'] as List? ?? [];
      return data.map((e) => KhataDueReportItem.fromJson(e)).toList();
    }
    return [];
  }
}
