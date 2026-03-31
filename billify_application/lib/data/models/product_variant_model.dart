import 'package:uuid/uuid.dart';

class ProductVariantModel {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final int stock;
  final String uomId;

  ProductVariantModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
    required this.uomId,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'] ?? '',
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      uomId: json['uomId'] ?? 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock': stock,
      'uomId': uomId,
    };
  }

  ProductVariantModel copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    int? stock,
    String? uomId,
  }) {
    return ProductVariantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      uomId: uomId ?? this.uomId,
    );
  }

  static ProductVariantModel empty() {
    return ProductVariantModel(
      id: const Uuid().v4(),
      name: '',
      barcode: '',
      price: 0.0,
      stock: 0,
      uomId: 'pcs',
    );
  }
}
