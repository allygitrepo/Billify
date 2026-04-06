import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/stock_history_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteInventoryDatasourceProvider = Provider<RemoteInventoryDatasource>((ref) {
  return RemoteInventoryDatasource(ref);
});

class RemoteInventoryDatasource {
  final Ref _ref;

  RemoteInventoryDatasource(this._ref);

  ApiService get _apiService => _ref.read(apiServiceProvider);

  Future<List<StockHistoryModel>> getInventoryLog(String businessId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.getInventoryLog(businessId));
      if (response.statusCode == 200) {
        final List<dynamic> logs = response.data['logs'];
        return logs.map((e) => StockHistoryModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching inventory log: $e");
      return [];
    }
  }

  Future<bool> updateStockBulk({
    required String businessId,
    required String? userId,
    required String type, // 'IN' or 'OUT'
    required String reason,
    String? referenceNo,
    String? entityName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.updateStock,
        data: {
          'business_id': int.tryParse(businessId),
          'user_id': userId != null ? int.tryParse(userId) : null,
          'type': type,
          'reason': reason,
          'reference_no': referenceNo,
          'entity_name': entityName,
          'items': items,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating stock bulk: $e");
      return false;
    }
  }
}
