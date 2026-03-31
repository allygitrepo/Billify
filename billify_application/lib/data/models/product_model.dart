import 'product_variant_model.dart';

class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final String? categoryId;
  final String uomId;
  final String? imageUrl;
  final bool hasVariants;
  final List<ProductVariantModel> variants;
  final String? selectedVariantId;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    this.categoryId,
    required this.uomId,
    this.imageUrl,
    this.hasVariants = false,
    this.variants = const [],
    this.selectedVariantId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      barcode: json['barcode'] ?? '',
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      categoryId: json['categoryId'],
      uomId: json['uomId'] ?? 'pcs',
      imageUrl: json['imageUrl'] as String?,
      hasVariants: json['hasVariants'] ?? false,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariantModel.fromJson(v))
              .toList() ??
          [],
      selectedVariantId: json['selectedVariantId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'uomId': uomId,
      'imageUrl': imageUrl,
      'hasVariants': hasVariants,
      'variants': variants.map((v) => v.toJson()).toList(),
      'selectedVariantId': selectedVariantId,
    };
  }

  ProductModel copyWith({
    String? id,
    String? barcode,
    String? name,
    double? price,
    int? stock,
    String? categoryId,
    String? uomId,
    String? imageUrl,
    bool? hasVariants,
    List<ProductVariantModel>? variants,
    String? selectedVariantId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      uomId: uomId ?? this.uomId,
      imageUrl: imageUrl ?? this.imageUrl,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
    );
  }
}


