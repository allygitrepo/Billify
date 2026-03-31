import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/uom_model.dart';

class UomRepository {
  final LocalStorageService _storage;
  final String _userId;
  final String _businessId;

  UomRepository(this._storage, this._userId, this._businessId);

  String get _uomDataKey => AppConstants.businessKey(_userId, _businessId, AppConstants.keyUomData);

  Future<void> saveUom(UomModel uom) async {
    final uoms = getUoms();
    final index = uoms.indexWhere((u) => u.id == uom.id);
    
    if (index >= 0) {
      uoms[index] = uom;
    } else {
      uoms.add(uom);
    }
    
    await _storage.setString(
      _uomDataKey,
      jsonEncode(uoms.map((e) => e.toJson()).toList()),
    );
  }

  List<UomModel> getUoms() {
    final data = _storage.getString(_uomDataKey);
    if (data == null) {
      // Seed default UOMs
      return _seedDefaultUoms();
    }
    
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => UomModel.fromJson(e)).toList();
  }

  List<UomModel> _seedDefaultUoms() {
    final defaults = [
      UomModel(id: 'kg', name: 'KG'),
      UomModel(id: 'litre', name: 'Litre'),
      UomModel(id: 'pcs', name: 'Pcs'),
    ];
    
    _storage.setString(
      _uomDataKey,
      jsonEncode(defaults.map((e) => e.toJson()).toList()),
    );
    
    return defaults;
  }

  Future<void> deleteUom(String id) async {
    final uoms = getUoms();
    uoms.removeWhere((u) => u.id == id);
    await _storage.setString(
      _uomDataKey,
      jsonEncode(uoms.map((e) => e.toJson()).toList()),
    );
  }
}
