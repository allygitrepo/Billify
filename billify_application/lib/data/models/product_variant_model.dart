import 'package:uuid/uuid.dart';

class ProductVariantModel {
  final String id;
  final String name;
  final String sku;
  final double price;
  final double openingStock;
  final double currentStock;
  final String uom;

  ProductVariantModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    double? openingStock,
    double? currentStock,
    double? stock, // Legacy support
    required this.uom,
  })  : this.openingStock = openingStock ?? stock ?? 0.0,
        this.currentStock = currentStock ?? stock ?? 0.0;

  // Alias for backward compatibility
  double get stock => currentStock;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final currentStockVal = double.tryParse(json['current_stock']?.toString() ?? '') ?? 
                            double.tryParse(json['stock']?.toString() ?? '') ?? 0.0;
    return ProductVariantModel(
      id: json['id'].toString(),
      name: json['name'],
      sku: json['sku'] ?? json['barcode'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      openingStock: double.tryParse(json['opening_stock']?.toString() ?? '') ?? currentStockVal,
      currentStock: currentStockVal,
      uom: json['uom']?.toString() ?? json['uomId']?.toString() ?? 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'opening_stock': openingStock,
      'current_stock': currentStock,
      'stock': currentStock, // Legacy
      'uom': uom,
    };
  }

  ProductVariantModel copyWith({
    String? id,
    String? name,
    String? sku,
    double? price,
    double? openingStock,
    double? currentStock,
    double? stock, // Legacy support
    String? uom,
  }) {
    return ProductVariantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? stock ?? this.currentStock,
      uom: uom ?? this.uom,
    );
  }

  static ProductVariantModel empty() {
    return ProductVariantModel(
      id: const Uuid().v4(),
      name: '',
      sku: '',
      price: 0.0,
      openingStock: 0.0,
      currentStock: 0.0,
      uom: 'pcs',
    );
  }
}

