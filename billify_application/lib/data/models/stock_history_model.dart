import 'package:billify_application/core/enums/stock_mode.dart';

class StockHistoryModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final StockMode type;
  final DateTime timestamp;
  final String reason;
  final String source; // 'manual', 'invoice', etc.

  StockHistoryModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.type,
    required this.timestamp,
    required this.reason,
    this.source = 'manual',
  });

  factory StockHistoryModel.fromJson(Map<String, dynamic> json) {
    return StockHistoryModel(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      type: json['type'] == 'inMode' ? StockMode.inMode : StockMode.outMode,
      timestamp: DateTime.parse(json['timestamp']),
      reason: json['reason'] ?? 'Manual Adjustment',
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'type': type == StockMode.inMode ? 'inMode' : 'outMode',
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
      'source': source,
    };
  }
}
