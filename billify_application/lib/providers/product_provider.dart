import 'package:billify_application/core/enums/stock_mode.dart';
import 'package:billify_application/data/models/stock_history_model.dart';
import 'package:billify_application/data/models/product_variant_model.dart';
import 'package:billify_application/data/repositories/product_repository.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/stock_history_provider.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final userId = ref.watch(authProvider).user?.email ?? 'guest';
  final businessId = ref.watch(businessProvider).currentBusinessId ?? 'default';
  return ProductRepository(storage, userId, businessId);
});

class ProductNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() {
    final repo = ref.watch(productRepositoryProvider);
    return repo.getProducts();
  }

  Future<void> saveProduct(ProductModel product) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.saveProduct(product);
    state = repo.getProducts();
  }

  ProductModel? findByBarcode(String barcode) {
    for (final product in state) {
      if (product.barcode == barcode) return product;
      if (product.hasVariants) {
        for (final variant in product.variants) {
          if (variant.barcode == barcode) {
            return product.copyWith(
              name: '${product.name} (${variant.name})',
              price: variant.price,
              barcode: variant.barcode,
              stock: variant.stock,
              selectedVariantId: variant.id,
            );
          }
        }
      }
    }
    return null;
  }

  Future<void> deleteProduct(String id) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.deleteProduct(id);
    state = repo.getProducts();
  }

  Future<void> updateStockBulk(Map<String, int> deltas, {StockMode mode = StockMode.inMode, required String reason}) async {
    final repo = ref.read(productRepositoryProvider);
    final historyRepo = ref.read(stockHistoryRepositoryProvider);
    final currentProducts = state;
    final List<ProductModel> updatedProducts = [];

    for (var entry in deltas.entries) {
      final compositeId = entry.key;
      final delta = entry.value;
      
      final parts = compositeId.split(':');
      final productId = parts[0];
      final variantId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      
      final index = currentProducts.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        final product = currentProducts[index];
        ProductModel updatedProduct;
        String historyProductName = product.name;

        if (variantId != null && product.hasVariants) {
          final variantIndex = product.variants.indexWhere((v) => v.id == variantId);
          if (variantIndex >= 0) {
            final variant = product.variants[variantIndex];
            final newVariantStock = (variant.stock + delta).clamp(0, 999999);
            final updatedVariants = List<ProductVariantModel>.from(product.variants);
            updatedVariants[variantIndex] = variant.copyWith(stock: newVariantStock);
            updatedProduct = product.copyWith(variants: updatedVariants);
            historyProductName = '${product.name} (${variant.name})';
          } else {
            updatedProduct = product; // Should not happen
          }
        } else {
          final newStock = (product.stock + delta).clamp(0, 999999);
          updatedProduct = product.copyWith(stock: newStock);
        }
        
        updatedProducts.add(updatedProduct);

        // Record history
        await historyRepo.saveHistory(
          StockHistoryModel(
            id: const Uuid().v4(),
            productId: productId,
            productName: historyProductName,
            quantity: delta.abs(),
            type: delta > 0 ? StockMode.inMode : StockMode.outMode,
            timestamp: DateTime.now(),
            reason: reason,
          ),
        );
      }
    }

    if (updatedProducts.isNotEmpty) {
      await repo.saveProducts(updatedProducts);
      state = repo.getProducts();
      ref.invalidate(stockHistoryProvider);
    }
  }
}

final productProvider = NotifierProvider<ProductNotifier, List<ProductModel>>(ProductNotifier.new);
