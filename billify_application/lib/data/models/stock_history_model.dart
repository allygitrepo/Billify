import 'package:billify/core/enums/stock_mode.dart';

class StockHistoryModel {
  final String id;
  final String product_id;
  final String variant_name;
  final double quantity_change;
  final StockMode change_type;
  final DateTime createdAt;
  final String reason;
  final String source; // 'manual', 'invoice', etc.

  StockHistoryModel({
    required this.id,
    required this.product_id,
    required this.variant_name,
    required this.quantity_change,
    required this.change_type,
    required this.createdAt,
    required this.reason,
    this.source = 'manual',
  });

  factory StockHistoryModel.fromJson(Map<String, dynamic> json) {
    final typeString = (json['change_type'] ?? json['type'])
        ?.toString()
        .toUpperCase();
    return StockHistoryModel(
      id: json['id'].toString(),
      product_id:
          json['product_id']?.toString() ?? json['productId']?.toString() ?? '',
      variant_name: json['variant_name'] ?? json['product']?['name'] ?? '',
      quantity_change:
          (json['quantity_change'] as num?)?.toDouble() ??
          (json['quantity'] as num?)?.toDouble() ??
          0.0,
      change_type: typeString == 'IN' ? StockMode.inMode : StockMode.outMode,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['timestamp'] ?? '') ??
          DateTime.now(),
      reason: json['reason'] ?? 'Manual Adjustment',
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': product_id,
      'variant_name': variant_name,
      'quantity_change': quantity_change,
      'change_type': change_type == StockMode.inMode ? 'IN' : 'OUT',
      'createdAt': createdAt.toIso8601String(),
      'reason': reason,
      'source': source,
    };
  }
}
