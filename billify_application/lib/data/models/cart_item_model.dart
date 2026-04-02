import 'package:billify_application/data/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final double? customPrice;
  final String? customName;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.customPrice,
    this.customName,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      customPrice: (json['customPrice'] as num?)?.toDouble(),
      customName: json['customName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'customPrice': customPrice,
      'customName': customName,
    };
  }

  double get price => customPrice ?? product.basePrice;
  String get name => customName ?? product.name;
  double get subtotal => price * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? customPrice,
    String? customName,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      customPrice: customPrice ?? this.customPrice,
      customName: customName ?? this.customName,
    );
  }
}
