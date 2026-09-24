import 'package:billify/core/enums/stock_mode.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/presentation/billing/widgets/weight_input_sheet.dart';
import 'package:billify/presentation/inventory/widgets/stock_item_tile.dart';
import 'package:billify/presentation/inventory/widgets/stock_mode_button.dart';
import 'package:billify/presentation/widgets/custom_button.dart';
import 'package:billify/presentation/widgets/error_handler.dart';
import 'package:billify/presentation/widgets/section_card.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StockAdjustmentTab extends ConsumerStatefulWidget {
  final VoidCallback onCommitSuccess;

  const StockAdjustmentTab({super.key, required this.onCommitSuccess});

  @override
  ConsumerState<StockAdjustmentTab> createState() => _StockAdjustmentTabState();
}

class _StockAdjustmentTabState extends ConsumerState<StockAdjustmentTab> {
  StockMode _mode = StockMode.inMode;
  final Map<String, double> _transactionItems = {};
  bool _isProcessing = false;
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  String _pickerSearchQuery = '';

  final List<String> _inReasons = [
    'Bulk Purchase',
    'Stock Return',
    'Manual Adjustment',
    'Other',
  ];
  final List<String> _outReasons = [
    'Damage Correction',
    'Return',
    'Manual Adjustment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedReason = _inReasons[0];
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _addItem(ProductModel product) {
    if (_mode == StockMode.outMode && product.stock <= 0) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Cannot remove stock from an out-of-stock item',
      );
      return;
    }

    if (product.is_weighted) {
      _showWeightInputSheet(product);
      return;
    }

    setState(() {
      final key = product.selectedVariantId != null
          ? '${product.id}:${product.selectedVariantId}'
          : product.id;
      _transactionItems[key] = (_transactionItems[key] ?? 0.0) + 1.0;
    });
  }

  void _showWeightInputSheet(ProductModel product, {double? initialQuantity}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeightInputSheet(
        product: product,
        buttonLabel: _mode == StockMode.inMode ? 'ADD STOCK' : 'REMOVE STOCK',
        onAdd: (quantity) {
          setState(() {
            final key = product.selectedVariantId != null
                ? '${product.id}:${product.selectedVariantId}'
                : product.id;

            if (initialQuantity != null) {
              _transactionItems[key] = quantity;
            } else {
              _transactionItems[key] =
                  (_transactionItems[key] ?? 0.0) + quantity;
            }
          });
        },
      ),
    );
  }

  void _updateQuantity(String compositeId, double newQuantity) {
    if (newQuantity <= 0) {
      setState(() => _transactionItems.remove(compositeId));
      return;
    }
    setState(() => _transactionItems[compositeId] = newQuantity);
  }

  Future<void> _handleCommit() async {
    if (_transactionItems.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final Map<String, double> deltas = {};
      _transactionItems.forEach((key, qty) {
        deltas[key] = _mode == StockMode.inMode ? qty : -qty;
      });

      final finalReason = _selectedReason == 'Other'
          ? (_otherReasonController.text.isEmpty
                ? 'Other'
                : _otherReasonController.text)
          : (_selectedReason ?? 'Manual Adjustment');

      await ref
          .read(productProvider.notifier)
          .updateStockBulk(
            deltas,
            mode: _mode,
            reason: finalReason,
            source: 'manual',
          );

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Stock updated successfully for ${_transactionItems.length} products',
        );
        setState(() => _transactionItems.clear());
        widget.onCommitSuccess();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showScannerDialog() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Scan Product Barcode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first.rawValue;
                    if (barcode != null) Navigator.pop(context, barcode);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (result != null) {
      final product = ref.read(productProvider.notifier).findByBarcode(result);
      if (product != null) {
        _addItem(product);
      } else {
        final canAdd = ref
            .read(authProvider)
            .hasPermission(PermissionModule.products, PermissionAction.add);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                canAdd
                    ? 'Product with barcode $result not found'
                    : 'Product not available',
              ),
              action: canAdd
                  ? SnackBarAction(
                      label: 'ADD NEW',
                      onPressed: () async {
                        final newProduct = await Navigator.pushNamed(
                          context,
                          '/products',
                          arguments: result,
                        );
                        if (newProduct != null && newProduct is ProductModel) {
                          _addItem(newProduct);
                          if (mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          }
                        }
                      },
                    )
                  : null,
            ),
          );
        }
      }
    }
  }

  void _showProductPicker() {
    final allProducts = ref.read(productsListProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          final filteredProducts = allProducts.where((p) {
            final query = _pickerSearchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.barcode.toLowerCase().contains(query) ||
                p.variants.any(
                  (v) =>
                      v.name.toLowerCase().contains(query) ||
                      v.sku.toLowerCase().contains(query),
                );
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Select Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) =>
                      setPickerState(() => _pickerSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search product or variant...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];

                      if (p.hasVariants && p.variants.isNotEmpty) {
                        return ExpansionTile(
                          leading: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.primaryTeal,
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${p.variants.length} Variants'),
                          children: p.variants
                              .map(
                                (v) => ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  title: Text(v.name),
                                  subtitle: Text(
                                    'Stock: ${v.stock} | SKU: ${v.sku}',
                                    style: TextStyle(
                                      color: v.stock <= 0 ? Colors.red : null,
                                      fontWeight: v.stock <= 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.add_circle_outline,
                                    color:
                                        (_mode == StockMode.outMode &&
                                            v.stock <= 0)
                                        ? Colors.grey
                                        : AppTheme.primaryTeal,
                                    size: 20,
                                  ),
                                  onTap: () {
                                    if (_mode == StockMode.outMode &&
                                        v.stock <= 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Product out of stock'),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pop(context);
                                    _addItem(
                                      p.copyWith(selectedVariantId: v.id),
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        );
                      }

                      return ListTile(
                        leading: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppTheme.primaryTeal,
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          'Stock: ${p.stock} | Barcode: ${p.barcode}',
                          style: TextStyle(
                            color: p.stock <= 0 ? Colors.red : null,
                            fontWeight: p.stock <= 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_circle_outline,
                          color: (_mode == StockMode.outMode && p.stock <= 0)
                              ? Colors.grey
                              : AppTheme.primaryTeal,
                        ),
                        onTap: () {
                          if (_mode == StockMode.outMode && p.stock <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product out of stock'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          _addItem(p);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsListProvider);
    final canUpdateStock = ref
        .watch(authProvider)
        .hasPermission(PermissionModule.inventory, PermissionAction.update);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Mode Switch (Stock IN / OUT)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SectionCard(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: StockModeButton(
                    label: 'STOCK IN',
                    isSelected: _mode == StockMode.inMode,
                    icon: Icons.add_circle_outline,
                    color: Colors.green,
                    onTap: () => setState(() {
                      _mode = StockMode.inMode;
                      _selectedReason = _inReasons[0];
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StockModeButton(
                    label: 'STOCK OUT',
                    isSelected: _mode == StockMode.outMode,
                    icon: Icons.remove_circle_outline,
                    color: Colors.orange,
                    onTap: () => setState(() {
                      _mode = StockMode.outMode;
                      _selectedReason = _outReasons[0];
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Buttons (Scan Barcode / Search Manual)
        if (canUpdateStock)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showScannerDialog,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('SCAN BARCODE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showProductPicker,
                    icon: const Icon(Icons.search),
                    label: const Text('SEARCH MANUAL'),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
        const Divider(),

        // Transaction List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _mode == StockMode.inMode ? 'TO BE ADDED' : 'TO BE REMOVED',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${_transactionItems.length} items',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        // Items List
        if (_transactionItems.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add products to adjust stock',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactionItems.length,
            itemBuilder: (context, index) {
              final compositeId = _transactionItems.keys.elementAt(index);
              final qty = _transactionItems[compositeId]!;

              final parts = compositeId.split(':');
              final productId = parts[0];
              final variantId = parts.length > 1 ? parts[1] : null;

              final product = allProducts
                  .where((p) => p.id == productId)
                  .firstOrNull;

              if (product == null) return const SizedBox.shrink();

              return StockItemTile(
                product: product,
                variantId: variantId,
                quantity: qty,
                onUpdateQty: (newQty) => _updateQuantity(compositeId, newQty),
                onWeightTap: product.is_weighted
                    ? () => _showWeightInputSheet(product, initialQuantity: qty)
                    : null,
                isStockOut: _mode == StockMode.outMode,
              );
            },
          ),

        // Transaction Reason
        if (_transactionItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Reason',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.info_outline, size: 18),
                    ),
                    items: (_mode == StockMode.inMode ? _inReasons : _outReasons)
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: const TextStyle(fontSize: 14)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedReason = val),
                  ),
                  if (_selectedReason == 'Other') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otherReasonController,
                      decoration: InputDecoration(
                        hintText: 'Enter specific reason',
                        hintStyle: const TextStyle(fontSize: 14),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Commit Button
        if (canUpdateStock)
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: 'COMMIT STOCK ${_mode == StockMode.inMode ? 'IN' : 'OUT'}',
              onPressed: _transactionItems.isEmpty ? null : _handleCommit,
              isLoading: _isProcessing,
              color: _mode == StockMode.inMode ? Colors.green : Colors.orange,
              isGradient: false,
            ),
          ),
      ],
    );
  }
}
