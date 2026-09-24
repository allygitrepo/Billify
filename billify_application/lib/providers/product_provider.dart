import 'package:billify/core/enums/stock_mode.dart';
import 'package:billify/core/errors/app_exception.dart';
import 'package:billify/data/datasources/remote_product_datasource.dart';
import 'package:billify/data/repositories/product_repository.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/state/product_state.dart';
import 'package:billify/providers/stock_history_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:billify/data/datasources/remote_inventory_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:billify/providers/state/product_state.dart';

/// Repository Provider with reactive multi-tenant scoping
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final remoteProductDatasource = ref.watch(remoteProductDatasourceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.businessOwnerId ?? user?.email ?? user?.mobile ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return ProductRepository(
    storage,
    remoteProductDatasource,
    userId,
    businessId,
  );
});

/// Comprehensive Product & Catalog State Notifier
class ProductNotifier extends Notifier<ProductState> {
  @override
  ProductState build() {
    final repo = ref.watch(productRepositoryProvider);
    // Pure build method: synchronously loads cached products without un-cancelled microtasks
    final cached = repo.getProducts();
    return ProductState(products: cached);
  }

  /// Sets search filter query reactively
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Sets category filter reactively
  void setCategoryFilter(String? category) {
    if (category == null || category == 'All') {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Explicit data fetch and synchronization
  Future<void> fetchAndSyncProducts() async {
    state = state.copyWith(isLoading: true, loadingMessage: 'Syncing products...');
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.fetchAndSyncProducts();
      final updated = repo.getProducts();
      state = state.copyWith(
        products: updated,
        isLoading: false,
        loadingMessage: null,
        clearFailure: true,
      );
    } catch (e) {
      final failure = e is AppException ? e.toFailure() : null;
      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        failure: failure,
      );
    }
  }

  /// Saves or updates a single product
  Future<void> saveProduct(ProductModel product) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.saveProduct(product);
      final updated = repo.getProducts();
      state = state.copyWith(
        products: updated,
        isLoading: false,
        clearFailure: true,
      );
    } catch (e) {
      final failure = e is AppException ? e.toFailure() : null;
      state = state.copyWith(isLoading: false, failure: failure);
      rethrow;
    }
  }

  /// Finds a product or variant matching a given barcode/SKU
  ProductModel? findByBarcode(String barcode) {
    if (barcode.isEmpty) return null;

    for (final product in state.products) {
      // 1. Check variant SKU matches
      if (product.hasVariants) {
        for (final variant in product.variants) {
          if (variant.sku == barcode) {
            return product.copyWith(
              name: variant.name.isNotEmpty
                  ? '${product.name} (${variant.name})'
                  : product.name,
              basePrice: variant.price,
              barcode: variant.sku,
              stock: variant.stock,
              selectedVariantId: variant.id,
              uom: variant.uom,
            );
          }
        }
      }

      // 2. Check main product barcode
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  /// Deletes a product by ID
  Future<void> deleteProduct(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.deleteProduct(id);
      final updated = repo.getProducts();
      state = state.copyWith(
        products: updated,
        isLoading: false,
        clearFailure: true,
      );
    } catch (e) {
      final failure = e is AppException ? e.toFailure() : null;
      state = state.copyWith(isLoading: false, failure: failure);
      rethrow;
    }
  }

  /// Bulk updates inventory quantities for Stock In / Stock Out
  Future<void> updateStockBulk(
    Map<String, double> deltas, {
    StockMode mode = StockMode.inMode,
    required String reason,
    String source = 'manual',
  }) async {
    final historyNotifier = ref.read(stockHistoryProvider.notifier);
    final businessProviderState = ref.read(businessProvider);
    final authState = ref.read(authProvider);

    final List<Map<String, dynamic>> items = [];
    final currentProducts = state.products;

    for (var entry in deltas.entries) {
      final compositeId = entry.key;
      final delta = entry.value;

      final parts = compositeId.split(':');
      final productIdString = parts[0];
      final variantId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;

      final product = currentProducts.firstWhere(
        (p) => p.id == productIdString,
        orElse: () => throw AppException(message: 'Product not found: $productIdString'),
      );

      String variantName = 'Default';
      if (variantId != null && product.hasVariants) {
        final variant = product.variants.firstWhere(
          (v) => v.id == variantId,
          orElse: () => product.variants.first,
        );
        variantName = variant.name;
      }

      items.add({
        'product_id': int.tryParse(productIdString),
        'variant_name': variantName,
        'quantity_change': delta,
        'unit_price': product.basePrice,
        'total_amount': product.basePrice * delta.abs(),
      });
    }

    if (items.isNotEmpty) {
      final remoteInventory = ref.read(remoteInventoryDatasourceProvider);
      final success = await remoteInventory.updateStockBulk(
        businessId: businessProviderState.currentBusinessId!,
        userId: authState.user?.id?.toString(),
        type: mode == StockMode.inMode ? 'IN' : 'OUT',
        reason: reason,
        items: items,
      );

      if (success) {
        await fetchAndSyncProducts();
        await historyNotifier.fetchAndSyncHistory();
      } else {
        throw const AppException(message: 'Failed to update stock items on server');
      }
    }
  }
}

/// Primary Product State Provider exposing the full ProductState machine
final productProvider = NotifierProvider<ProductNotifier, ProductState>(
  ProductNotifier.new,
);

/// Convenience Provider exposing the raw List<ProductModel>
final productsListProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(productProvider).products;
});

/// Reactive filtered products selector (computes query and category matches reactively)
final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(productProvider).filteredProducts;
});
