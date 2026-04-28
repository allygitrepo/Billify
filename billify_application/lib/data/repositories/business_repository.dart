import 'package:billify/data/datasources/business_datasource.dart';
import 'package:billify/data/datasources/remote_business_datasource.dart';
import 'package:billify/data/models/business_model.dart';

class BusinessRepository {
  final BusinessDatasource _datasource;
  final RemoteBusinessDatasource _remoteDatasource;

  BusinessRepository(this._datasource, this._remoteDatasource);

  Future<bool> saveBusiness(BusinessModel business) async {
    // Save locally first for immediate responsiveness
    await _datasource.saveBusiness(business);

    try {
      if (int.tryParse(business.id) != null) {
        // ID is numeric, likely from server, so update
        await _remoteDatasource.updateBusiness(business);
      } else {
        // New business, create on server
        final remoteBusiness = await _remoteDatasource.createBusiness(business);
        if (remoteBusiness != null) {
          // Replace local temp ID with server ID
          await _datasource.saveBusiness(remoteBusiness);
        }
      }
    } catch (e) {
      print("Error during remote business save: $e");
    }

    return true;
  }

  List<BusinessModel> getBusinesses() {
    return _datasource.getBusinesses();
  }

  String? getCurrentBusinessId() {
    return _datasource.getCurrentBusinessId();
  }

  Future<bool> setCurrentBusinessId(String id) async {
    return await _datasource.setCurrentBusinessId(id);
  }

  Future<void> clearAll() async {
    await _datasource.clearAll();
  }

  Future<void> syncBusinesses() async {
    try {
      final remoteBusinesses = await _remoteDatasource.getMyBusinesses();
      for (final b in remoteBusinesses) {
        await _datasource.saveBusiness(b);
      }
    } catch (e) {
      // Log or handle error
    }
  }
}
