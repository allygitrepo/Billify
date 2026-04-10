import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerReportsServiceProvider = Provider<CustomerReportsService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return CustomerReportsService(apiService);
});

class CustomerReportsService {
  final ApiService _apiService;

  CustomerReportsService(this._apiService);

  Future<Map<String, dynamic>> fetchCustomerAnalytics(String businessId, {String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get(
      ApiEndpoints.getCustomersAnalytics(businessId),
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data;
    }
    return {
      'summary': {'totalCustomers': 0, 'totalReceivable': 0, 'totalPayable': 0, 'netBalance': 0},
      'customers': []
    };
  }
}
