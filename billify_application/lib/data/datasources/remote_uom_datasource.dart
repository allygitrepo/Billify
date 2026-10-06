import 'package:billify/core/constants/api_endpoints.dart';
import 'package:billify/core/services/api_service.dart';
import 'package:billify/data/models/uom_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteUomDatasourceProvider = Provider<RemoteUomDatasource>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return RemoteUomDatasource(apiService);
});

class RemoteUomDatasource {
  final ApiService _apiService;

  RemoteUomDatasource(this._apiService);

  Future<List<UomModel>> getUoms(String businessId) async {
    final response = await _apiService.get(ApiEndpoints.getUoms(businessId));
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['uoms'] ?? [];
      return data.map((e) => UomModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<UomModel?> createUom(UomModel uom, String businessId) async {
    final response = await _apiService.post(
      '${ApiEndpoints.uomsBase}/create',
      data: {
        'business_id': int.tryParse(businessId),
        'name': uom.name,
        'shortCode': uom.shortCode,
      },
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return UomModel.fromJson(response.data['uom']);
    }
    return null;
  }

  Future<UomModel?> updateUom(UomModel uom) async {
    final response = await _apiService.put(
      ApiEndpoints.updateUom(uom.id),
      data: {'name': uom.name, 'shortCode': uom.shortCode},
    );
    if (response.statusCode == 200) {
      return UomModel.fromJson(response.data['uom']);
    }
    return null;
  }

  Future<bool> deleteUom(String id) async {
    final response = await _apiService.delete(ApiEndpoints.deleteUom(id));
    return response.statusCode == 200;
  }
}

