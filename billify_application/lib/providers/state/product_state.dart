import 'package:billify/core/errors/app_failure.dart';
import 'package:billify/data/models/product_model.dart';

/// Immutable State representation for Product & Catalog management
class ProductState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? loadingMessage;
  final AppFailure? failure;
  final String searchQuery;
  final String? selectedCategory;

  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.loadingMessage,
    this.failure,
    this.searchQuery = '',
    this.selectedCategory,
  });

  /// Filtered list of products based on active search query and category filter
  List<ProductModel> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    return products.where((p) {
      final matchesCategory = selectedCategory == null || 
          selectedCategory == 'All' || 
          p.category_id == selectedCategory;
          
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      final matchesName = p.name.toLowerCase().contains(query);
      final matchesBarcode = p.barcode.toLowerCase().contains(query);
      final matchesVariants = p.hasVariants && p.variants.any(
        (v) => v.name.toLowerCase().contains(query) || v.sku.toLowerCase().contains(query),
      );

      return matchesName || matchesBarcode || matchesVariants;
    }).toList();
  }

  /// Total count of in-stock items
  int get inStockCount => products.where((p) => p.stock > 0).length;

  /// Total count of out-of-stock items
  int get outOfStockCount => products.where((p) => p.stock <= 0).length;

  /// Low stock items count (stock < 10)
  int get lowStockCount => products.where((p) => p.totalStock > 0 && p.totalStock < 10).length;

  ProductState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? loadingMessage,
    AppFailure? failure,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    bool clearFailure = false,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      failure: clearFailure ? null : (failure ?? this.failure),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }
}
