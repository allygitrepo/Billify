import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/business_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteBusinessDatasource {
  final ApiService _apiService;

  RemoteBusinessDatasource(this._apiService);

  Future<List<BusinessModel>> getMyBusinesses() async {
    try {
      final response = await _apiService.get(ApiEndpoints.getBusinesses);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['businesses'];
        return data.map((json) => BusinessModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching businesses: $e");
      return [];
    }
  }

  Future<BusinessModel?> createBusiness(BusinessModel business) async {
    try {
      final response = await _apiService.post(
        '/businesses/create',
        data: {
          'businessName': business.name,
          'phone': business.phone,
          'gstin': business.gstin,
          'address': business.address,
          'photo': business.business_logo,
        },
      );
      if (response.statusCode == 201) {
        return BusinessModel.fromJson(response.data['business']);
      }
      return null;
    } catch (e) {
      print("Error creating business: $e");
      return null;
    }
  }
  
  Future<BusinessModel?> updateBusiness(BusinessModel business) async {
    try {
      final response = await _apiService.put(
        '/businesses/update/${business.id}',
        data: {
          'name': business.name,
          'phone': business.phone,
          'gstin': business.gstin,
          'address': business.address,
          'photo': business.business_logo,
        },
      );
      if (response.statusCode == 200) {
        return BusinessModel.fromJson(response.data['business']);
      }
      return null;
    } catch (e) {
      print("Error updating business: $e");
      return null;
    }
  }
}

final remoteBusinessDatasourceProvider = Provider<RemoteBusinessDatasource>((ref) {
  return RemoteBusinessDatasource(ref.read(apiServiceProvider));
});
