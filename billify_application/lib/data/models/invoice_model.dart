import 'package:billify_application/data/models/business_model.dart';
import 'package:billify_application/data/models/cart_item_model.dart';

class InvoiceModel {
  final String id;
  final DateTime date;
  final BusinessModel business;
  final List<CartItemModel> items;
  final double total_amount;
  final double tax_amount;
  final double gst_amount;
  final double final_amount;
  final String staff_name;

  InvoiceModel({
    required this.id,
    required this.date,
    required this.business,
    required this.items,
    required this.total_amount,
    required this.tax_amount,
    required this.gst_amount,
    required this.final_amount,
    required this.staff_name,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      business: BusinessModel.fromJson(json['business']),
      items: (json['items'] as List).map((e) => CartItemModel.fromJson(e)).toList(),
      total_amount: (json['total_amount'] as num?)?.toDouble() ?? (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax_amount: (json['tax_amount'] as num?)?.toDouble() ?? (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      gst_amount: (json['gst_amount'] as num?)?.toDouble() ?? (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      final_amount: (json['final_amount'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      staff_name: json['staff_name'] ?? json['staffName'] ?? 'Owner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'business': business.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'total_amount': total_amount,
      'tax_amount': tax_amount,
      'gst_amount': gst_amount,
      'final_amount': final_amount,
      'staff_name': staff_name,
    };
  }
}

