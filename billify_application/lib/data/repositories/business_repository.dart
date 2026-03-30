import 'package:billify_application/data/datasources/business_datasource.dart';
import 'package:billify_application/data/models/business_model.dart';

class BusinessRepository {
  final BusinessDatasource _datasource;

  BusinessRepository(this._datasource);

  Future<bool> saveBusiness(BusinessModel business) async {
    return await _datasource.saveBusiness(business);
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
}
