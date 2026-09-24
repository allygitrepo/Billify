import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/presentation/inventory/widgets/inventory_product_tile.dart';
import 'package:billify/presentation/widgets/empty_state_view.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockPortfolioTab extends ConsumerStatefulWidget {
  const StockPortfolioTab({super.key});

  @override
  ConsumerState<StockPortfolioTab> createState() => _StockPortfolioTabState();
}

class _StockPortfolioTabState extends ConsumerState<StockPortfolioTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsListProvider);

    final filteredProducts = allProducts.where((p) {
      if (_searchQuery.isEmpty) return true;
      final matchesName = p.name.toLowerCase().contains(_searchQuery);
      final matchesBarcode = p.barcode.toLowerCase().contains(_searchQuery);
      final matchesVariant = p.variants.any(
        (v) => v.name.toLowerCase().contains(_searchQuery) || v.sku.toLowerCase().contains(_searchQuery),
      );
      return matchesName || matchesBarcode || matchesVariant;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by name, SKU, or barcode...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.primaryTeal,
              ),
              filled: true,
              fillColor: AppTheme.softGrey.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const EmptyStateView(
                  title: 'No products found',
                  subtitle: 'Try adjusting your search terms or add new inventory',
                  icon: Icons.inventory_2_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return InventoryProductTile(product: filteredProducts[index]);
                  },
                ),
        ),
      ],
    );
  }
}
