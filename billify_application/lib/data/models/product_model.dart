class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final String? categoryId;
  final String uomId;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    this.categoryId,
    required this.uomId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      barcode: json['barcode'] ?? '',
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      categoryId: json['categoryId'],
      uomId: json['uomId'] ?? 'pcs', // Default fallback
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
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      uomId: uomId ?? this.uomId,
    );
  }
}
