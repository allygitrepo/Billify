import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/presentation/inventory/widgets/stock_adjustment_tab.dart';
import 'package:billify/presentation/inventory/widgets/stock_history_tab.dart';
import 'package:billify/presentation/inventory/widgets/stock_portfolio_tab.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:billify/providers/stock_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockManagementPage extends ConsumerStatefulWidget {
  const StockManagementPage({super.key});

  @override
  ConsumerState<StockManagementPage> createState() =>
      _StockManagementPageState();
}

class _StockManagementPageState extends ConsumerState<StockManagementPage> {
  int _selectedTabIndex = 0; // 0: Adjustment, 1: Portfolio, 2: History

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Inventory',
            onPressed: () async {
              await ref.read(productProvider.notifier).fetchAndSyncProducts();
              await ref.read(stockHistoryProvider.notifier).fetchAndSyncHistory();
            },
          ),
        ],
      ),
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

          // Active Tab Body
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                StockAdjustmentTab(
                  onCommitSuccess: () {
                    // Switch to Portfolio tab to immediately see the updated inventory
                    setState(() => _selectedTabIndex = 1);
                    ref.read(productProvider.notifier).fetchAndSyncProducts();
                  },
                ),
                const StockPortfolioTab(),
                const StockHistoryTab(),
              ],
            ),
          ),
        ],
      ),
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
