import 'package:billify_application/core/enums/stock_mode.dart';
import 'dart:convert';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/core/utils/image_utils.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/data/models/product_variant_model.dart';
import 'package:billify_application/data/models/stock_history_model.dart';
import 'package:billify_application/presentation/widgets/custom_button.dart';
import 'package:billify_application/presentation/widgets/section_card.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:billify_application/providers/stock_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:billify_application/data/models/user_permission.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/presentation/billing/widgets/weight_input_sheet.dart';
import 'package:billify_application/providers/uom_provider.dart';
import 'package:billify_application/presentation/widgets/error_handler.dart';

class StockManagementPage extends ConsumerStatefulWidget {
  const StockManagementPage({super.key});

  @override
  ConsumerState<StockManagementPage> createState() =>
      _StockManagementPageState();
}

class _StockManagementPageState extends ConsumerState<StockManagementPage> {
  StockMode _mode = StockMode.inMode;
  int _selectedTabIndex = 0; // 0: Transaction, 1: In-Stock, 2: History
  final Map<String, double> _transactionItems = {}; // ProductId -> Quantity
  bool _isProcessing = false;
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ledgerSearchController = TextEditingController();
  String _searchQuery = '';
  String _ledgerSearchQuery = '';
  String _selectedLedgerFilter = 'All'; // 'All', 'Sale', 'Manual'
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
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _ledgerSearchController.addListener(() {
      setState(
        () => _ledgerSearchQuery = _ledgerSearchController.text.toLowerCase(),
      );
    });
  }

  void _addItem(ProductModel product) {
    // Stock Out Validation
    if (_mode == StockMode.outMode) {
      if (product.stock <= 0) {
        ErrorHandler.showErrorSnackBar(context, 'Cannot remove stock from an out-of-stock item');
        return;
      }
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
              // If editing, replace quantity
              _transactionItems[key] = quantity;
            } else {
              // If adding new, increment
              _transactionItems[key] = (_transactionItems[key] ?? 0.0) + quantity;
            }
          });
        },
      ),
    );
  }

  void _updateQuantity(String compositeId, double newQuantity) {
    if (newQuantity <= 0) {
      setState(() {
        _transactionItems.remove(compositeId);
      });
      return;
    }
    setState(() {
      _transactionItems[compositeId] = newQuantity;
    });
  }

  Future<void> _handleCommit() async {
    if (_transactionItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // For Out mode, we send negative deltas
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
        setState(() {
          _transactionItems.clear();
          _selectedTabIndex = 1; // Switch to Portfolio to see the change
        });
        // Force refresh products to update the list
        ref.read(productProvider.notifier).fetchAndSyncProducts();
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
    final allProducts = ref.read(productProvider);
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
    final allProducts = ref.watch(productProvider);
    final history = ref.watch(stockHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Management')),
      body: Column(
        children: [
          // Navigation Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TabButton(
                  label: 'Adjustment',
                  isSelected: _selectedTabIndex == 0,
                  onTap: () => setState(() => _selectedTabIndex = 0),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Portfolio',
                  isSelected: _selectedTabIndex == 1,
                  onTap: () => setState(() => _selectedTabIndex = 1),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'History',
                  isSelected: _selectedTabIndex == 2,
                  onTap: () => setState(() => _selectedTabIndex = 2),
                ),
              ],
            ),
          ),

          if (_selectedTabIndex == 0) ...[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ... (Rest of Transaction implementation remains similar)
                  // Header - Mode Swtich
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SectionCard(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
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
                            child: _ModeButton(
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

                  // Actions
                  if (ref
                      .watch(authProvider)
                      .hasPermission(
                        PermissionModule.inventory,
                        PermissionAction.update,
                      ))
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

                  // List Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _mode == StockMode.inMode
                              ? 'TO BE ADDED'
                              : 'TO BE REMOVED',
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

                  // Transaction List
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
                              'Add products to see them here',
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
                        final compositeId = _transactionItems.keys.elementAt(
                          index,
                        );
                        final qty = _transactionItems[compositeId]!;

                        final parts = compositeId.split(':');
                        final productId = parts[0];
                        final variantId = parts.length > 1 ? parts[1] : null;

                        final p = allProducts.where(
                          (p) => p.id == productId,
                        ).firstOrNull;

                        if (p == null) return const SizedBox.shrink();

                        return _StockItemTile(
                          product: p,
                          variantId: variantId,
                          quantity: qty,
                          onUpdateQty: (newQty) =>
                              _updateQuantity(compositeId, newQty),
                          isStockOut: _mode == StockMode.outMode,
                        );
                      },
                    ),

                  // Reason Selector
                  if (_transactionItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SectionCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                              items:
                                  (_mode == StockMode.inMode
                                          ? _inReasons
                                          : _outReasons)
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(
                                            r,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedReason = val),
                            ),
                            if (_selectedReason == 'Other') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _otherReasonController,
                                decoration: InputDecoration(
                                  hintText: 'Enter specific reason',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
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

                  const SizedBox(height: 8),

                  // Commit Button
                  if (ref
                      .watch(authProvider)
                      .hasPermission(
                        PermissionModule.inventory,
                        PermissionAction.update,
                      ))
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomButton(
                        text:
                            'COMMIT STOCK ${_mode == StockMode.inMode ? 'IN' : 'OUT'}',
                        onPressed: _transactionItems.isEmpty
                            ? null
                            : _handleCommit,
                        isLoading: _isProcessing,
                        color: _mode == StockMode.inMode
                            ? Colors.green
                            : Colors.orange,
                        isGradient: false,
                      ),
                    ),
                ],
              ),
            ),
          ] else if (_selectedTabIndex == 1) ...[
            // Portfolio / In-Stock Tab
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
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
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  final p = allProducts[index];

                  // Filter logic
                  if (_searchQuery.isNotEmpty) {
                    final matchesName = p.name.toLowerCase().contains(
                      _searchQuery,
                    );
                    final matchesVariant = p.variants.any(
                      (v) =>
                          v.name.toLowerCase().contains(_searchQuery)
                    );

                    if (!matchesName && !matchesVariant) {
                      return const SizedBox.shrink();
                    }
                  }

                  return _InventoryProductTile(product: p);
                },
              ),
            ),
          ] else ...[
            // Ledger / History View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _ledgerSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search ledger (product, reason)...',
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
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Sale', 'Manual'].map((filter) {
                        final isSelected = _selectedLedgerFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val)
                                setState(() => _selectedLedgerFilter = filter);
                            },
                            selectedColor: AppTheme.primaryTeal.withOpacity(
                              0.2,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No stock history found',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildHistoryList(history),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    _searchController.dispose();
    _ledgerSearchController.dispose();
    super.dispose();
  }

  Widget _buildHistoryList(List<StockHistoryModel> history) {
    // Filter history
    final filteredHistory = history.where((item) {
      final matchesSearch =
          item.variant_name.toLowerCase().contains(_ledgerSearchQuery) ||
          item.reason.toLowerCase().contains(_ledgerSearchQuery);

      bool matchesFilter = true;
      if (_selectedLedgerFilter == 'Sale') {
        matchesFilter = item.source == 'invoice';
      } else if (_selectedLedgerFilter == 'Manual') {
        matchesFilter = item.source == 'manual';
      }

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredHistory.isEmpty) {
      return const Center(
        child: Text(
          'No results match your filters',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group history by date
    final Map<String, List<StockHistoryModel>> grouped = {};
    final dateFormat = DateFormat('MMM dd, yyyy');

    for (var item in filteredHistory) {
      final dateKey = dateFormat.format(item.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    final sortedDates = grouped.keys.toList();

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTeal,
                  fontSize: 14,
                ),
              ),
            ),
            ...items.map((item) => _HistoryItem(history: item)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryTeal.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryTeal
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.primaryTeal
                    : Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  final StockHistoryModel history;

  const _HistoryItem({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('hh:mm a');
    final isStockIn = history.change_type == StockMode.inMode;
    final isInvoice = history.source == 'invoice';

    // Find product to get image
    final product = ref
        .watch(productProvider)
        .where((p) => p.id == history.product_id)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    (isInvoice
                            ? AppTheme.primaryTeal
                            : (isStockIn ? Colors.green : Colors.orange))
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: product?.photo != null && product!.photo!.isNotEmpty
                  ? Image.memory(
                      ImageUtils.decodeBase64(product.photo!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                      ),
                    )
                  : Icon(
                      isInvoice
                          ? Icons.receipt_long_outlined
                          : (isStockIn
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline),
                      color: isInvoice
                          ? AppTheme.primaryTeal
                          : (isStockIn ? Colors.green : Colors.orange),
                      size: 20,
                    ),
            ),
            // Tiny indicator icon at bottom right
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isInvoice
                      ? AppTheme.primaryTeal
                      : (isStockIn ? Colors.green : Colors.orange),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  isInvoice
                      ? Icons.receipt
                      : (isStockIn ? Icons.add : Icons.remove),
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                history.variant_name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isInvoice ? Colors.blue : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                history.source.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isInvoice ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason: ${history.reason}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTeal,
              ),
            ),
            Text(
              timeFormat.format(history.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isStockIn ? Colors.green : Colors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${isStockIn ? '+' : ''}${history.quantity_change}',
            style: TextStyle(
              color: isStockIn ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockItemTile extends StatelessWidget {
  final ProductModel product;
  final String? variantId;
  final double quantity;
  final Function(double) onUpdateQty;
  final bool isStockOut;

  const _StockItemTile({
    required this.product,
    this.variantId,
    required this.quantity,
    required this.onUpdateQty,
    required this.isStockOut,
  });

  @override
  Widget build(BuildContext context) {
    String name = product.name;
    String barcode = product.barcode;
    double currentStock = product.stock;

    if (variantId != null) {
      final variant = product.variants.where((v) => v.id == variantId).firstOrNull;
      if (variant != null) {
        name = '${product.name} (${variant.name})';
        barcode = variant.sku;
        currentStock = variant.stock;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.photo != null && product.photo!.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            try {
                              return Image.memory(
                                ImageUtils.decodeBase64(product.photo!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 18,
                                ),
                              );
                            } catch (e) {
                              return const Icon(
                                Icons.image_not_supported_outlined,
                                size: 18,
                              );
                            }
                          },
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppTheme.primaryTeal,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Stock: $currentStock ${product.uom.isNotEmpty ? product.uom : ''} | Barcode: $barcode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Internal Controls for list
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () {
                        if (product.is_weighted) {
                          // Allow editing with weight screen
                          final parent = context.findAncestorStateOfType<
                            _StockManagementPageState
                          >();
                          parent?._showWeightInputSheet(
                            product,
                            initialQuantity: quantity,
                          );
                        } else {
                          onUpdateQty(quantity - 1);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    InkWell(
                      onTap: () {
                        if (product.is_weighted) {
                          final parent = context.findAncestorStateOfType<
                            _StockManagementPageState
                          >();
                          parent?._showWeightInputSheet(
                            product,
                            initialQuantity: quantity,
                          );
                        } else {
                          _showManualQuantityDialog(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () {
                        if (product.is_weighted) {
                          final parent = context.findAncestorStateOfType<
                            _StockManagementPageState
                          >();
                          parent?._showWeightInputSheet(
                            product,
                            initialQuantity: quantity,
                          );
                        } else {
                          onUpdateQty(quantity + 1);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
            if (isStockOut && currentStock < quantity)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Insufficient stock! Remaining: $currentStock',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualQuantityDialog(BuildContext context) async {
    final controller = TextEditingController(text: quantity.toString());
    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Quantity for ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter number',
            suffixText: product.uom.isNotEmpty ? product.uom : 'units',
          ),
          onSubmitted: (val) {
            final qty = double.tryParse(val);
            if (qty != null) Navigator.pop(context, qty);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final qty = double.tryParse(controller.text);
              if (qty != null) Navigator.pop(context, qty);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      onUpdateQty(result);
    }
  }
}

class _InventoryProductTile extends ConsumerWidget {
  final ProductModel product;

  const _InventoryProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uoms = ref.watch(uomProvider);
    final resolvedUom = uoms.where((u) => u.id == product.uom).firstOrNull?.shortCode ?? product.uom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        key: PageStorageKey('inventory_${product.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: product.photo != null && product.photo!.isNotEmpty
              ? Builder(
                  builder: (context) {
                    try {
                      return Image.memory(
                        ImageUtils.decodeBase64(product.photo!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined, size: 20),
                      );
                    } catch (e) {
                      return const Icon(Icons.image_not_supported_outlined, size: 20);
                    }
                  },
                )
              : const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primaryTeal,
                  size: 24,
                ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: product.hasVariants
            ? Text(
                '${product.variants.length} Variants',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              )
            : Text(
                'Price: ₹${product.basePrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
        trailing: !product.hasVariants
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (product.stock <= 0
                          ? Colors.red
                          : (product.stock > 10
                                ? Colors.green
                                : Colors.orange))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.stock <= 0 ? 'OUT OF STOCK' : '${product.stock} $resolvedUom',
                  style: TextStyle(
                    color: product.stock <= 0
                        ? Colors.red
                        : (product.stock > 10 ? Colors.green : Colors.orange),
                    fontWeight: FontWeight.bold,
                    fontSize: product.stock <= 0 ? 10 : 12,
                  ),
                ),
              )
            : null,
        children: product.hasVariants
            ? product.variants
                  .map(
                    (v) => _InventoryVariantTile(variant: v, uom: resolvedUom),
                  )
                  .toList()
            : [],
      ),
    );
  }
}

class _InventoryVariantTile extends StatelessWidget {
  final ProductVariantModel variant;
  final String uom;

  const _InventoryVariantTile({required this.variant, required this.uom});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.subdirectory_arrow_right,
              size: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Price: ₹${variant.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (variant.stock <= 0
                          ? Colors.red
                          : (variant.stock > 5 ? Colors.green : Colors.orange))
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              variant.stock <= 0
                  ? 'OUT OF STOCK'
                  : '${variant.stock} ${uom.isNotEmpty ? uom : ''}',
              style: TextStyle(
                color: variant.stock <= 0
                    ? Colors.red
                    : (variant.stock > 5 ? Colors.green : Colors.orange),
                fontWeight: FontWeight.bold,
                fontSize: variant.stock <= 0 ? 10 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
