import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/features/analytics/profit_reports/models/profit_report_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profitReportsServiceProvider = Provider<ProfitReportsService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ProfitReportsService(apiService);
});

class ProfitReportsService {
  final ApiService _apiService;

  ProfitReportsService(this._apiService);

  Map<String, dynamic> _buildParams(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) {
    return {
      'business_id': businessId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (branchId != null) 'branch_id': branchId,
    };
  }

  Future<ProfitSummaryModel> getProfitSummary(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getProfitSummary(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      return ProfitSummaryModel.fromJson(response.data['summary'] ?? {});
    }
    return ProfitSummaryModel.empty();
  }

  Future<List<ProfitChartData>> getProfitTrend(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getProfitSummary(businessId), // Trend data usually comes from summary or specialized trend endpoint, matching sales pattern
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['chartData'] as List? ?? [];
      return data.map((e) => ProfitChartData.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<ProductProfitData>> getProfitByProducts(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getProfitByProducts(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['topProducts'] as List? ?? [];
      return data.map((e) => ProductProfitData.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<CategoryProfitData>> getProfitByCategories(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getProfitByCategories(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['topCategories'] as List? ?? [];
      return data.map((e) => CategoryProfitData.fromJson(e)).toList();
    }
    return [];
  }
}
