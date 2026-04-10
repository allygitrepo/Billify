import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/features/analytics/sales_reports/models/sales_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final salesReportsServiceProvider = Provider<SalesReportsService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return SalesReportsService(apiService);
});

class SalesReportsService {
  final ApiService _apiService;

  SalesReportsService(this._apiService);

  Map<String, dynamic> _buildParams(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) {
    return {
      'business_id': businessId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (branchId != null) 'branch_id': branchId,
    };
  }

  Future<SalesSummaryModel> getSalesSummary(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getSalesSummary(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      return SalesSummaryModel.fromJson(response.data['summary']);
    }
    return SalesSummaryModel.empty();
  }

  Future<List<SalesChartData>> getSalesTrend(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getSalesTrend(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['trend'] as List;
      return data.map((e) => SalesChartData.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<TopProductData>> getTopProducts(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getTopProducts(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['products'] as List;
      return data.map((e) => TopProductData.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<CategorySalesData>> getCategorySales(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getCategorySales(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['categories'] as List;
      return data.map((e) => CategorySalesData.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<PaymentMethodData>> getPaymentSummary(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId}) async {
    final response = await _apiService.get(
      ApiEndpoints.getPaymentSummary(businessId),
      queryParameters: _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['payments'] as List;
      return data.map((e) => PaymentMethodData.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<InvoiceModel>> getSalesList(String businessId, {DateTime? startDate, DateTime? endDate, String? branchId, int page = 1, int limit = 20}) async {
    final params = _buildParams(businessId, startDate: startDate, endDate: endDate, branchId: branchId);
    params['page'] = page;
    params['limit'] = limit;

    final response = await _apiService.get(
      ApiEndpoints.getSalesList(businessId),
      queryParameters: params,
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['invoices'] as List;
      return data.map((e) => InvoiceModel.fromJson(e)).toList();
    }
    return [];
  }
}
