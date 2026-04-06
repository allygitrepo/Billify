import 'package:uuid/uuid.dart';

class ProductVariantModel {
  final String id;
  final String name;
  final String sku;
  final double price;
  final int stock;
  final String uom;

  ProductVariantModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.uom,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'].toString(),
      name: json['name'],
      sku: json['sku'] ?? json['barcode'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      uom: json['uom']?.toString() ?? json['uomId']?.toString() ?? 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'stock': stock,
      'uom': uom,
    };
  }

  ProductVariantModel copyWith({
    String? id,
    String? name,
    String? sku,
    double? price,
    int? stock,
    String? uom,
  }) {
    return ProductVariantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      uom: uom ?? this.uom,
    );
  }

  static ProductVariantModel empty() {
    return ProductVariantModel(
      id: const Uuid().v4(),
      name: '',
      sku: '',
      price: 0.0,
      stock: 0,
      uom: 'pcs',
    );
  }
}

