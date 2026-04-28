import 'dart:convert';
import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/data/datasources/remote_uom_datasource.dart';
import 'package:billify/data/models/uom_model.dart';

class UomRepository {
  final LocalStorageService _storage;
  final RemoteUomDatasource _remoteDatasource;
  final String _userId;
  final String _businessId;

  UomRepository(
    this._storage,
    this._remoteDatasource,
    this._userId,
    this._businessId,
  );

  String get _uomDataKey =>
      AppConstants.businessKey(_userId, _businessId, AppConstants.keyUomData);

  Future<void> fetchAndSyncUoms() async {
    if (int.tryParse(_businessId) == null) {
      return; // Skip sync for temporary or invalid business IDs
    }
    try {
      final remoteUoms = await _remoteDatasource.getUoms(_businessId);
      if (remoteUoms.isNotEmpty) {
        await _storage.setString(
          _uomDataKey,
          jsonEncode(remoteUoms.map((e) => e.toJson()).toList()),
        );
      }
    } catch (e) {
      print("Error syncing UOMs: $e");
    }
  }

  Future<void> saveUom(UomModel uom) async {
    if (int.tryParse(_businessId) == null) {
      print("Skipping remote UOM save: Business ID is temporary.");
      return;
    }
    try {
      // 1. Try remote save
      UomModel? savedUom;
      if (uom.id.contains('-') || int.tryParse(uom.id) == null) {
        // New UOM (UUID or non-numeric placeholder)
        savedUom = await _remoteDatasource.createUom(uom, _businessId);
      } else {
        // Existing UOM (numeric ID)
        savedUom = await _remoteDatasource.updateUom(uom);
      }

      if (savedUom != null) {
        // 2. Update local with server response
        final uoms = getUoms();
        final index = uoms.indexWhere((u) => u.id == uom.id);

        if (index >= 0) {
          uoms[index] = savedUom;
        } else {
          uoms.add(savedUom);
        }

        await _storage.setString(
          _uomDataKey,
          jsonEncode(uoms.map((e) => e.toJson()).toList()),
        );
      }
    } catch (e) {
      print("Error saving UOM: $e");
    }
  }

  List<UomModel> getUoms() {
    final data = _storage.getString(_uomDataKey);
    if (data == null) {
      return _seedDefaultUoms();
    }

    try {
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => UomModel.fromJson(e)).toList();
    } catch (_) {
      return _seedDefaultUoms();
    }
  }

  List<UomModel> _seedDefaultUoms() {
    final defaults = [
      UomModel(id: 'kg', name: 'KG', shortCode: 'kg'),
      UomModel(id: 'litre', name: 'Litre', shortCode: 'ltr'),
      UomModel(id: 'pcs', name: 'Pcs', shortCode: 'pcs'),
    ];

    _storage.setString(
      _uomDataKey,
      jsonEncode(defaults.map((e) => e.toJson()).toList()),
    );

    return defaults;
  }

  Future<void> deleteUom(String id) async {
    try {
      final success = await _remoteDatasource.deleteUom(id);
      if (success) {
        final uoms = getUoms();
        uoms.removeWhere((u) => u.id == id);
        await _storage.setString(
          _uomDataKey,
          jsonEncode(uoms.map((e) => e.toJson()).toList()),
        );
      }
    } catch (e) {
      print("Error deleting UOM: $e");
    }
  }
}
