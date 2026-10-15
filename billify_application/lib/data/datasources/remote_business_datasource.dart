import 'package:billify/core/constants/api_endpoints.dart';
import 'package:billify/core/services/api_service.dart';
import 'package:billify/core/utils/app_logger.dart';
import 'package:billify/data/models/business_model.dart';
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
    } catch (e, stackTrace) {
      AppLogger.error("Error fetching businesses", error: e, stackTrace: stackTrace, tag: 'RemoteBusinessDatasource');
      return [];
    }
  }

  Future<BusinessModel?> createBusiness(BusinessModel business) async {
    try {
      final response = await _apiService.post(
        '/businesses',
        data: {
          'businessName': business.name,
          'name': business.name,
          'phone': business.phone,
          'business_phone': business.phone,
          'businessPhone': business.phone,
          'gstin': business.gstin,
          'address': business.address,
          'business_address': business.address,
          'photo': business.business_logo,
          'business_logo': business.business_logo,
          'taxPercentage': business.tax_percentage,
          'tax': business.tax_percentage,
          'gstPercentage': business.gst_percentage,
          'gst_percentage': business.gst_percentage,
          'invoicePrefix': business.invoice_prefix,
          'invoice_prefix': business.invoice_prefix,
        },
      );
      if (response.statusCode == 201) {
        return BusinessModel.fromJson(response.data['business']);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error("Error creating business", error: e, stackTrace: stackTrace, tag: 'RemoteBusinessDatasource');
      return null;
    }
  }

  Future<BusinessModel?> updateBusiness(BusinessModel business) async {
    try {
      final response = await _apiService.put(
        '/businesses/${business.id}',
        data: {
          'business_id': business.id,
          'name': business.name,
          'business_name': business.name,
          'phone': business.phone,
          'business_phone': business.phone,
          'businessPhone': business.phone,
          'gstin': business.gstin,
          'gst_number': business.gstin,
          'address': business.address,
          'business_address': business.address,
          'photo': business.business_logo,
          'business_logo': business.business_logo,
          'tax': business.tax_percentage,
          'taxPercentage': business.tax_percentage,
          'gst_percentage': business.gst_percentage,
          'gstPercentage': business.gst_percentage,
          'invoice_prefix': business.invoice_prefix,
          'invoicePrefix': business.invoice_prefix,
        },
      );
      if (response.statusCode == 200) {
        return BusinessModel.fromJson(response.data['business']);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error("Error updating business", error: e, stackTrace: stackTrace, tag: 'RemoteBusinessDatasource');
      return null;
    }
  }
}

final remoteBusinessDatasourceProvider = Provider<RemoteBusinessDatasource>((
  ref,
) {
  return RemoteBusinessDatasource(ref.read(apiServiceProvider));
});
