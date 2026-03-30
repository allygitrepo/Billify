import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/stock_history_model.dart';

class StockHistoryRepository {
  final LocalStorageService _storage;

  StockHistoryRepository(this._storage);

  Future<void> saveHistory(StockHistoryModel history) async {
    final allHistory = getHistory();
    allHistory.insert(0, history); // Add to beginning (most recent first)
    
    // Limit to 200 entries to save space
    final limitedHistory = allHistory.take(200).toList();
    
    await _storage.setString(
      AppConstants.keyStockHistory,
      jsonEncode(limitedHistory.map((e) => e.toJson()).toList()),
    );
  }

  List<StockHistoryModel> getHistory() {
    final data = _storage.getString(AppConstants.keyStockHistory);
    if (data == null) return [];
    
    try {
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => StockHistoryModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
