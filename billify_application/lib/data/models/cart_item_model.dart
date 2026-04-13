import 'package:billify_application/data/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final double quantity;
  final double? customPrice;
  final String? customName;

  CartItemModel({
    required this.product,
    this.quantity = 1.0,
    this.customPrice,
    this.customName,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final ProductModel product;
    if (json['product'] != null) {
      product = ProductModel.fromJson(json['product']);
    } else {
      // Synthesize product from flat fields (common in synced invoice items)
      product = ProductModel(
        id: (json['product_id'] ?? json['productId'] ?? '0').toString(),
        name: json['product_name'] ?? json['productName'] ?? 'Deleted Product',
        barcode: '',
        basePrice: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
        stock: 0.0,
        uom: 'pcs',
      );
    }

    return CartItemModel(
      product: product,
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 1.0,
      customPrice: double.tryParse(json['customPrice']?.toString() ?? json['price']?.toString() ?? '') ?? 0.0,
      customName: (json['customName'] ?? json['product_name'] ?? json['productName'] ?? 'Unknown').toString(),
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

  Map<String, dynamic> toServerJson() {
    return {
      'productId': int.tryParse(product.id),
      'productName': product.name,
      'variantName': product.selectedVariantId != null ? product.name.split(' (').last.replaceAll(')', '') : '',
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  double get price {
    if (customPrice != null) return customPrice!;
    return product.is_weighted ? product.price_per_unit : product.basePrice;
  }
  String get name => customName ?? product.name;
  double get subtotal => price * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    double? quantity,
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
