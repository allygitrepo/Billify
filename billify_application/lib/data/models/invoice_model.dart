import 'package:billify_application/data/models/business_model.dart';
import 'package:billify_application/data/models/cart_item_model.dart';

class InvoiceModel {
  final String id;
  final DateTime date;
  final BusinessModel business;
  final List<CartItemModel> items;
  final double subtotal;
  final double taxAmount;
  final double gstAmount;
  final double total;
  final String staffName;

  InvoiceModel({
    required this.id,
    required this.date,
    required this.business,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.gstAmount,
    required this.total,
    required this.staffName,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      business: BusinessModel.fromJson(json['business']),
      items: (json['items'] as List).map((e) => CartItemModel.fromJson(e)).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      staffName: json['staffName'] ?? 'Owner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'business': business.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'gstAmount': gstAmount,
      'total': total,
      'staffName': staffName,
    };
  }
}
