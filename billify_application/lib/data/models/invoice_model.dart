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
      id: json['invoice_number']?.toString() ?? json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['createdAt']?.toString() ?? json['date']?.toString() ?? '') ?? DateTime.now(),
      business: json['business'] != null ? BusinessModel.fromJson(json['business']) : BusinessModel(
        id: json['business_id']?.toString() ?? '',
        name: 'Business',
        phone: '',
        tax_percentage: 0.0,
        gst_percentage: 0.0,
      ), // Fallback if backend omits business
      items: json['items'] != null ? (json['items'] as List).map((e) => CartItemModel.fromJson(e)).toList() : [],
      total_amount: double.tryParse(json['total_amount']?.toString() ?? json['subtotal']?.toString() ?? '') ?? 0.0,
      tax_amount: double.tryParse(json['tax_amount']?.toString() ?? json['taxAmount']?.toString() ?? '') ?? 0.0,
      gst_amount: double.tryParse(json['gst_amount']?.toString() ?? json['gstAmount']?.toString() ?? '') ?? 0.0,
      final_amount: double.tryParse(json['final_amount']?.toString() ?? json['total']?.toString() ?? '') ?? 0.0,
      staff_name: (json['user'] != null && json['user']['name'] != null) 
          ? json['user']['name'] 
          : (json['staff_name'] ?? json['staffName'] ?? 'Owner'),
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

  InvoiceModel copyWith({
    String? id,
    DateTime? date,
    BusinessModel? business,
    List<CartItemModel>? items,
    double? total_amount,
    double? tax_amount,
    double? gst_amount,
    double? final_amount,
    String? staff_name,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      date: date ?? this.date,
      business: business ?? this.business,
      items: items ?? this.items,
      total_amount: total_amount ?? this.total_amount,
      tax_amount: tax_amount ?? this.tax_amount,
      gst_amount: gst_amount ?? this.gst_amount,
      final_amount: final_amount ?? this.final_amount,
      staff_name: staff_name ?? this.staff_name,
    );
  }
}

