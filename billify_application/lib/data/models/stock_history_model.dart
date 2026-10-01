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
    final double rawQty = (json['quantity_change'] != null
            ? double.tryParse(json['quantity_change'].toString())
            : null) ??
        (json['quantity'] != null
            ? double.tryParse(json['quantity'].toString())
            : null) ??
        (json['quantityChange'] != null
            ? double.tryParse(json['quantityChange'].toString())
            : null) ??
        0.0;

    final productName = json['product']?['name']?.toString() ?? '';
    final rawVariantName = json['variant_name']?.toString() ?? '';
    String displayName = rawVariantName;
    if (displayName.isEmpty ||
        displayName == 'Default' ||
        displayName == 'No Variant') {
      displayName = productName.isNotEmpty ? productName : 'Product';
    }

    final rawSource = json['source']?.toString().toLowerCase() ?? '';
    final rawReason = json['reason']?.toString() ?? 'Manual Adjustment';
    final isInvoice = rawSource == 'invoice' ||
        rawReason.toLowerCase().contains('sale') ||
        rawReason.toLowerCase().contains('inv');

    return StockHistoryModel(
      id: json['id']?.toString() ?? '',
      product_id: json['product_id']?.toString() ??
          json['productId']?.toString() ??
          '',
      variant_name: displayName,
      quantity_change: rawQty.abs(),
      change_type: typeString == 'IN' ? StockMode.inMode : StockMode.outMode,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ??
              DateTime.now())
          : (json['timestamp'] != null
              ? (DateTime.tryParse(json['timestamp'].toString())?.toLocal() ??
                  DateTime.now())
              : DateTime.now()),
      reason: rawReason,
      source: isInvoice ? 'invoice' : 'manual',
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
