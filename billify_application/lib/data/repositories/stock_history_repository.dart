import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/datasources/remote_inventory_datasource.dart';
import 'package:billify_application/data/models/stock_history_model.dart';

class StockHistoryRepository {
  final LocalStorageService _storage;
  final RemoteInventoryDatasource _remoteDatasource;
  final String _userId;
  final String _businessId;

  StockHistoryRepository(this._storage, this._remoteDatasource, this._userId, this._businessId);

  String get _stockHistoryKey => AppConstants.businessKey(_userId, _businessId, AppConstants.keyStockHistory);

  Future<void> fetchAndSyncHistory() async {
    try {
      final remoteLogs = await _remoteDatasource.getInventoryLog(_businessId);
      if (remoteLogs.isNotEmpty) {
        final List<Map<String, dynamic>> jsonData = remoteLogs.map((e) => e.toJson()).toList();
        await _storage.setString(
          _stockHistoryKey,
          jsonEncode(jsonData),
        );
      }
    } catch (e) {
      print("Error syncing stock history: $e");
    }
  }

  Future<void> saveHistory(StockHistoryModel history) async {
    final allHistory = getHistory();
    allHistory.insert(0, history); // Add to beginning (most recent first)
    
    // Limit to 200 entries to save space
    final limitedHistory = allHistory.take(200).toList();
    
    await _storage.setString(
      _stockHistoryKey,
      jsonEncode(limitedHistory.map((e) => e.toJson()).toList()),
    );
  }

  List<StockHistoryModel> getHistory() {
    final data = _storage.getString(_stockHistoryKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => StockHistoryModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
