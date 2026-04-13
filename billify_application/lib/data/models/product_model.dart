import 'product_variant_model.dart';

class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final double basePrice;
  // final double purchasePrice;
  final double openingStock;
  final double currentStock;
  final String? category_id;
  final String uom;
  final String? photo;
  final bool hasVariants;
  final List<ProductVariantModel> variants;
  final String? selectedVariantId;
  final bool is_weighted;
  final int? base_uom_id;
  final double price_per_unit;
 
  ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.basePrice,
    // this.purchasePrice = 0.0,
    double? openingStock,
    double? currentStock,
    double? stock, // Legacy support
    this.category_id,
    required this.uom,
    this.photo,
    this.hasVariants = false,
    this.variants = const [],
    this.selectedVariantId,
    this.is_weighted = false,
    this.base_uom_id,
    this.price_per_unit = 0.0,
  })  : this.openingStock = openingStock ?? stock ?? 0.0,
        this.currentStock = currentStock ?? stock ?? 0.0;

  // Alias for backward compatibility
  double get stock => currentStock;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final currentStockVal = double.tryParse(json['current_stock']?.toString() ?? '') ?? 
                            double.tryParse(json['stock']?.toString() ?? '') ?? 0.0;
    return ProductModel(
      id: json['id'].toString(),
      barcode: json['barcode'] ?? json['sku'] ?? '',
      name: json['name'],
      basePrice: double.tryParse(json['basePrice']?.toString() ?? '') ?? double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      // purchasePrice: double.tryParse(json['purchasePrice']?.toString() ?? '') ?? 0.0,
      openingStock: double.tryParse(json['opening_stock']?.toString() ?? '') ?? currentStockVal,
      currentStock: currentStockVal,
      category_id: json['category_id']?.toString() ?? json['categoryId']?.toString(),
      uom: json['uom']?.toString() ?? json['uomId']?.toString() ?? 'pcs',
      photo: json['photo'] ?? json['imageUrl'],
      hasVariants: json['hasVariants'] ?? ((json['variants'] as List<dynamic>?)?.isNotEmpty ?? false),
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariantModel.fromJson(v))
              .toList() ??
          [],
      selectedVariantId: json['selectedVariantId']?.toString(),
      is_weighted: json['is_weighted'] ?? false,
      base_uom_id: json['base_uom_id'] != null ? int.tryParse(json['base_uom_id'].toString()) : null,
      price_per_unit: double.tryParse(json['price_per_unit']?.toString() ?? '') ?? 
                      (json['is_weighted'] == true ? double.tryParse(json['price']?.toString() ?? '') ?? 0.0 : 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': basePrice, // Backend now expects 'price'
      'basePrice': basePrice, // Keep for legacy
      'opening_stock': openingStock,
      'current_stock': currentStock,
      'stock': currentStock, // Legacy
      'category_id': category_id,
      'uom': uom,
      'photo': photo,
      'has_variants': hasVariants, // Backend expects 'has_variants'
      'hasVariants': hasVariants, // Keep for legacy
      'variants': variants.map((v) => v.toJson()).toList(),
      'selectedVariantId': selectedVariantId,
      'is_weighted': is_weighted,
      'base_uom_id': base_uom_id,
      'price_per_unit': price_per_unit,
    };
  }

  ProductModel copyWith({
    String? id,
    String? barcode,
    String? name,
    double? basePrice,
    // double? purchasePrice,
    double? openingStock,
    double? currentStock,
    double? stock, // Legacy support
    String? category_id,
    String? uom,
    String? photo,
    bool? hasVariants,
    List<ProductVariantModel>? variants,
    String? selectedVariantId,
    bool? is_weighted,
    int? base_uom_id,
    double? price_per_unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      // purchasePrice: purchasePrice ?? this.purchasePrice,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? stock ?? this.currentStock,
      category_id: category_id ?? this.category_id,
      uom: uom ?? this.uom,
      photo: photo ?? this.photo,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
      is_weighted: is_weighted ?? this.is_weighted,
      base_uom_id: base_uom_id ?? this.base_uom_id,
      price_per_unit: price_per_unit ?? this.price_per_unit,
    );
  }

  double get totalStock {
    if (!hasVariants || variants.isEmpty) return stock;
    return variants.fold(0.0, (sum, v) => sum + v.stock);
  }
}



