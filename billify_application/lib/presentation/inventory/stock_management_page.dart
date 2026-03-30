import 'package:billify_application/core/enums/stock_mode.dart';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/data/models/stock_history_model.dart';
import 'package:billify_application/presentation/widgets/custom_button.dart';
import 'package:billify_application/presentation/widgets/section_card.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:billify_application/providers/stock_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

class StockManagementPage extends ConsumerStatefulWidget {
  const StockManagementPage({super.key});

  @override
  ConsumerState<StockManagementPage> createState() =>
      _StockManagementPageState();
}

class _StockManagementPageState extends ConsumerState<StockManagementPage> {
  StockMode _mode = StockMode.inMode;
  bool _showHistory = false;
  final Map<String, int> _transactionItems = {}; // ProductId -> Quantity
  bool _isProcessing = false;

  void _addItem(ProductModel product) {
    setState(() {
      _transactionItems[product.id] = (_transactionItems[product.id] ?? 0) + 1;
    });
  }

  void _updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() {
        _transactionItems.remove(productId);
      });
      return;
    }
    setState(() {
      _transactionItems[productId] = newQuantity;
    });
  }

  Future<void> _handleCommit() async {
    if (_transactionItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // For Out mode, we send negative deltas
      final Map<String, int> deltas = {};
      _transactionItems.forEach((id, qty) {
        deltas[id] = _mode == StockMode.inMode ? qty : -qty;
      });

      await ref.read(productProvider.notifier).updateStockBulk(deltas, mode: _mode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock updated successfully for ${_transactionItems.length} products',
            ),
          ),
        );
        setState(() {
          _transactionItems.clear();
          _showHistory = true; // Switch to history to see the change
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product with barcode $result not found'),
              action: SnackBarAction(
                label: 'ADD NEW',
                onPressed: () async {
                  final newProduct = await Navigator.pushNamed(
                    context,
                    '/add-product',
                    arguments: result,
                  );
                  if (newProduct != null && newProduct is ProductModel) {
                    _addItem(newProduct);
                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                  }
                },
              ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Select Product',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  final p = allProducts[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('Stock: ${p.stock} | Barcode: ${p.barcode}'),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primaryTeal,
                    ),
                    onTap: () {
                      _addItem(p);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
                  label: 'Transaction',
                  isSelected: !_showHistory,
                  onTap: () => setState(() => _showHistory = false),
                ),
                const SizedBox(width: 12),
                _TabButton(
                  label: 'History',
                  isSelected: _showHistory,
                  onTap: () => setState(() => _showHistory = true),
                ),
              ],
            ),
          ),

          if (!_showHistory) ...[
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
                        onTap: () => setState(() => _mode = StockMode.inMode),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeButton(
                        label: 'STOCK OUT',
                        isSelected: _mode == StockMode.outMode,
                        icon: Icons.remove_circle_outline,
                        color: Colors.orange,
                        onTap: () => setState(() => _mode = StockMode.outMode),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
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

            // Transaction List
            Expanded(
              child: _transactionItems.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                      itemCount: _transactionItems.length,
                      itemBuilder: (context, index) {
                        final id = _transactionItems.keys.elementAt(index);
                        final qty = _transactionItems[id]!;
                        final p = allProducts.firstWhere((p) => p.id == id);
                        return _StockItemTile(
                          product: p,
                          quantity: qty,
                          onUpdateQty: (newQty) => _updateQuantity(id, newQty),
                          isStockOut: _mode == StockMode.outMode,
                        );
                      },
                    ),
            ),

            // Commit Button
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
          ] else ...[
            // History View
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No stock history found',
                            style: TextStyle(color: Colors.grey),
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

  Widget _buildHistoryList(List<StockHistoryModel> history) {
    // Group history by date
    final Map<String, List<StockHistoryModel>> grouped = {};
    final dateFormat = DateFormat('MMM dd, yyyy');

    for (var item in history) {
      final dateKey = dateFormat.format(item.timestamp);
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
            color: isSelected ? AppTheme.primaryTeal.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryTeal : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final StockHistoryModel history;

  const _HistoryItem({required this.history});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final isStockIn = history.type == StockMode.inMode;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isStockIn ? Colors.green : Colors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isStockIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: isStockIn ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          history.productName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          timeFormat.format(history.timestamp),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isStockIn ? Colors.green : Colors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${isStockIn ? '+' : '-'}${history.quantity}',
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
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
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
                  color: isSelected ? Colors.white : Colors.black87,
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
  final int quantity;
  final Function(int) onUpdateQty;
  final bool isStockOut;

  const _StockItemTile({
    required this.product,
    required this.quantity,
    required this.onUpdateQty,
    required this.isStockOut,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
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
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Stock: ${product.stock}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                      onPressed: () => onUpdateQty(quantity - 1),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    InkWell(
                      onTap: () => _showManualQuantityDialog(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
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
                      onPressed: () => onUpdateQty(quantity + 1),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
            if (isStockOut && product.stock < quantity)
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
                      'Insufficient stock! Remaining: ${product.stock}',
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
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Quantity for ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter number',
            suffixText: 'units',
          ),
          onSubmitted: (val) {
            final qty = int.tryParse(val);
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
              final qty = int.tryParse(controller.text);
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
