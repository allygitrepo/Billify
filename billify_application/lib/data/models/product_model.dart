import 'product_variant_model.dart';

class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final double basePrice;
  final int stock;
  final String? category_id;
  final String uom;
  final String? photo;
  final bool hasVariants;
  final List<ProductVariantModel> variants;
  final String? selectedVariantId;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.basePrice,
    required this.stock,
    this.category_id,
    required this.uom,
    this.photo,
    this.hasVariants = false,
    this.variants = const [],
    this.selectedVariantId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      barcode: json['barcode'] ?? json['sku'] ?? '',
      name: json['name'],
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      category_id: json['category_id']?.toString() ?? json['categoryId']?.toString(),
      uom: json['uom'] ?? json['uomId'] ?? 'pcs',
      photo: json['photo'] ?? json['imageUrl'],
      hasVariants: json['hasVariants'] ?? false,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariantModel.fromJson(v))
              .toList() ??
          [],
      selectedVariantId: json['selectedVariantId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'basePrice': basePrice,
      'stock': stock,
      'category_id': category_id,
      'uom': uom,
      'photo': photo,
      'hasVariants': hasVariants,
      'variants': variants.map((v) => v.toJson()).toList(),
      'selectedVariantId': selectedVariantId,
    };
  }

  ProductModel copyWith({
    String? id,
    String? barcode,
    String? name,
    double? basePrice,
    int? stock,
    String? category_id,
    String? uom,
    String? photo,
    bool? hasVariants,
    List<ProductVariantModel>? variants,
    String? selectedVariantId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      stock: stock ?? this.stock,
      category_id: category_id ?? this.category_id,
      uom: uom ?? this.uom,
      photo: photo ?? this.photo,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
    );
  }

  int get totalStock {
    if (!hasVariants || variants.isEmpty) return stock;
    return variants.fold(0, (sum, v) => sum + v.stock);
  }
}



