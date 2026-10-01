import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/stock_history_model.dart';
import 'package:billify/presentation/inventory/widgets/stock_history_item_tile.dart';
import 'package:billify/presentation/widgets/empty_state_view.dart';
import 'package:billify/providers/stock_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StockHistoryTab extends ConsumerStatefulWidget {
  const StockHistoryTab({super.key});

  @override
  ConsumerState<StockHistoryTab> createState() => _StockHistoryTabState();
}

class _StockHistoryTabState extends ConsumerState<StockHistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Sale', 'Manual'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockHistoryProvider.notifier).fetchAndSyncHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(stockHistoryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search ledger (product, reason)...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryTeal,
                  ),
                  filled: true,
                  fillColor: AppTheme.softGrey.withValues(alpha: 0.5),
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
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                        selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(stockHistoryProvider.notifier).fetchAndSyncHistory();
            },
            child: _buildHistoryList(history),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<StockHistoryModel> history) {
    // Filter history based on search query and source filter
    final filteredHistory = history.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.variant_name.toLowerCase().contains(_searchQuery) ||
          item.reason.toLowerCase().contains(_searchQuery);

      bool matchesFilter = true;
      final isSale = item.source.toLowerCase() == 'invoice' ||
          item.reason.toLowerCase().contains('sale') ||
          item.reason.toLowerCase().contains('inv');

      if (_selectedFilter == 'Sale') {
        matchesFilter = isSale;
      } else if (_selectedFilter == 'Manual') {
        matchesFilter = !isSale;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredHistory.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyStateView(
            title: 'No stock history found',
            subtitle: 'Transactions and manual adjustments will appear here',
            icon: Icons.history_rounded,
          ),
        ],
      );
    }

    // Group history entries by date
    final Map<String, List<StockHistoryModel>> grouped = {};
    final dateFormat = DateFormat('MMM dd, yyyy');

    for (var item in filteredHistory) {
      final dateKey = dateFormat.format(item.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
            ...items.map((item) => StockHistoryItemTile(history: item)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
