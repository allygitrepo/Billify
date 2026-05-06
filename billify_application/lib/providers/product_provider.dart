import 'package:billify/core/enums/stock_mode.dart';
import 'package:billify/data/datasources/remote_product_datasource.dart';
import 'package:billify/data/repositories/product_repository.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/stock_history_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:billify/data/datasources/remote_inventory_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ProductNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() {
    final repo = ref.watch(productRepositoryProvider);
    // Trigger async sync when building
    Future.microtask(() => fetchAndSyncProducts());
    return repo.getProducts();
  }

  Future<void> fetchAndSyncProducts() async {
    final repo = ref.read(productRepositoryProvider);
    await repo.fetchAndSyncProducts();
    state = repo.getProducts();
  }

  Future<void> saveProduct(ProductModel product) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.saveProduct(product);
    state = repo.getProducts();
  }

  ProductModel? findByBarcode(String barcode) {
    if (barcode.isEmpty) return null;

    for (final product in state) {
      // 1. Try finding a variant match first
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
              uom: variant.uom, // Ensure UOM is also from variant
            );
          }
        }
      }

      // 2. Then try matching the main product if no variant matched
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  Future<void> deleteProduct(String id) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.deleteProduct(id);
    state = repo.getProducts();
  }

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
    final currentProducts = state;

    for (var entry in deltas.entries) {
      final compositeId = entry.key;
      final delta = entry
          .value; // total delta (not signed if mode is separate, but we pass final delta)

      final parts = compositeId.split(':');
      final productIdString = parts[0];
      final variantId = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1]
          : null;

      final product = currentProducts.firstWhere(
        (p) => p.id == productIdString,
      );

      String variantName = 'Default';
      if (variantId != null && product.hasVariants) {
        final variant = product.variants.firstWhere((v) => v.id == variantId);
        variantName = variant.name;
      }

      items.add({
        'product_id': int.tryParse(productIdString),
        'variant_name': variantName,
        'quantity_change':
            delta, // This is already signed from UI (+qty for IN, -qty for OUT)
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
        // Force refresh everything
        await fetchAndSyncProducts();
        await historyNotifier.fetchAndSyncHistory();
      } else {
        throw Exception("Failed to update stock items on server");
      }
    }
  }
}

final productProvider = NotifierProvider<ProductNotifier, List<ProductModel>>(
  ProductNotifier.new,
);
