import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/presentation/product/widgets/product_form_bottom_sheet.dart';
import 'package:billify/presentation/product/widgets/product_list_tile.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
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
                      ...categories.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
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
