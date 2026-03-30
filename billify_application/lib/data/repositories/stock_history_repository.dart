import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/stock_history_model.dart';

class StockHistoryRepository {
  final LocalStorageService _storage;
  final String _userId;

  StockHistoryRepository(this._storage, this._userId);

  String get _stockHistoryKey => AppConstants.userKey(_userId, AppConstants.keyStockHistory);

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
