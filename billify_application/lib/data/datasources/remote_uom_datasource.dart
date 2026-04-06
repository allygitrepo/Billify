import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/uom_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteUomDatasourceProvider = Provider<RemoteUomDatasource>((ref) {
  return RemoteUomDatasource(ref);
});

class RemoteUomDatasource {
  final Ref _ref;

  RemoteUomDatasource(this._ref);

  ApiService get _apiService => _ref.read(apiServiceProvider);

  Future<List<UomModel>> getUoms(String businessId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.getUoms(businessId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['uoms'];
        return data.map((e) => UomModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching UOMs: $e");
      return [];
    }
  }

  Future<UomModel?> createUom(UomModel uom, String businessId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.uomsBase + '/create',
        data: {
          'business_id': int.tryParse(businessId),
          'name': uom.name,
          'shortCode': uom.shortCode,
        },
      );
      if (response.statusCode == 201) {
        return UomModel.fromJson(response.data['uom']);
      }
      return null;
    } catch (e) {
      print("Error creating UOM: $e");
      return null;
    }
  }

  Future<UomModel?> updateUom(UomModel uom) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.updateUom(uom.id),
        data: {
          'name': uom.name,
          'shortCode': uom.shortCode,
        },
      );
      if (response.statusCode == 200) {
        return UomModel.fromJson(response.data['uom']);
      }
      return null;
    } catch (e) {
      print("Error updating UOM: $e");
      return null;
    }
  }

  Future<bool> deleteUom(String id) async {
    try {
      final response = await _apiService.delete(ApiEndpoints.deleteUom(id));
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting UOM: $e");
      return false;
    }
  }
}
