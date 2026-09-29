import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/category_model.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/presentation/product/widgets/product_form_bottom_sheet.dart';
import 'package:billify/presentation/product/widgets/product_list_tile.dart';
import 'package:billify/presentation/widgets/app_banner_ad.dart';
import 'package:billify/presentation/widgets/app_confirmation_dialog.dart';
import 'package:billify/presentation/widgets/empty_state_view.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/category_provider.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductManagementPage extends ConsumerStatefulWidget {
  final String? initialBarcode;

  const ProductManagementPage({super.key, this.initialBarcode});

  @override
  ConsumerState<ProductManagementPage> createState() =>
      _ProductManagementPageState();
}

class _ProductManagementPageState
    extends ConsumerState<ProductManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // If initial barcode is passed (from scanner), open bottom sheet immediately
    if (widget.initialBarcode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ProductFormBottomSheet.show(context, barcode: widget.initialBarcode);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteDialog(ProductModel product) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context,
      itemName: product.name,
    );

    if (confirmed) {
      await ref.read(productProvider.notifier).deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productList = ref.watch(productsListProvider);
    final categories = ref.watch(categoryProvider);
    final canAdd = ref
        .watch(authProvider)
        .hasPermission(PermissionModule.products, PermissionAction.add);

    // Reactive filter logic
    final query = _searchController.text.trim().toLowerCase();
    final filteredProducts = productList.where((product) {
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query);

      final matchesCategory = _selectedCategoryId == null ||
          product.category_id == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Products',
            onPressed: () =>
                ref.read(productProvider.notifier).fetchAndSyncProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final uniqueCats = <String, CategoryModel>{};
                      for (final c in categories) {
                        if (c.id != null && c.id!.isNotEmpty && !uniqueCats.containsKey(c.id!)) {
                          uniqueCats[c.id!] = c;
                        }
                      }
                      final categoryList = uniqueCats.values.toList();
                      final effectiveCatId = (_selectedCategoryId != null && uniqueCats.containsKey(_selectedCategoryId))
                          ? _selectedCategoryId
                          : null;

                      return DropdownButtonFormField<String>(
                        key: ValueKey('cat_filter_${effectiveCatId}_${categoryList.length}'),
                        value: effectiveCatId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          hintText: 'Category',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All'),
                          ),
                          ...categoryList.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedCategoryId = val),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(productProvider.notifier).fetchAndSyncProducts(),
              child: filteredProducts.isEmpty
                  ? EmptyStateView(
                      title: productList.isEmpty
                          ? 'No products added yet'
                          : 'No products match your search',
                      subtitle: productList.isEmpty
                          ? 'Tap the + button below to add your first product'
                          : 'Try changing category filter or search terms',
                      icon: Icons.inventory_2_outlined,
                      actionLabel: productList.isEmpty && canAdd ? 'ADD PRODUCT' : null,
                      onAction: productList.isEmpty && canAdd
                          ? () => ProductFormBottomSheet.show(context)
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ProductListTile(
                          product: product,
                          onEdit: () => ProductFormBottomSheet.show(
                            context,
                            product: product,
                          ),
                          onDelete: () => _showDeleteDialog(product),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        child: AppBannerAd(),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton(
              onPressed: () => ProductFormBottomSheet.show(context),
              backgroundColor: AppTheme.primaryTeal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
