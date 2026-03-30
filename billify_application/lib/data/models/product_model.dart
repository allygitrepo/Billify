class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final String? unit;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    this.unit,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'stock': stock,
      'unit': unit,
    };
  }

  ProductModel copyWith({
    String? id,
    String? barcode,
    String? name,
    double? price,
    int? stock,
    String? unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
    );
  }
}
