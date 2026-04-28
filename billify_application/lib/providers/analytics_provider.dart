import 'package:billify/data/models/analytics_models.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:billify/providers/invoice_provider.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:billify/providers/category_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum AnalyticsDateFilter { today, week, month }

class AnalyticsState {
  final AnalyticsSummary summary;
  final List<ChartDataPoint> salesTrend;
  final List<ChartDataPoint> topProducts;
  final List<PaymentMethodData> paymentMethods;
  final List<CategorySalesData> categorySales;
  final bool isLoading;

  AnalyticsState({
    required this.summary,
    this.salesTrend = const [],
    this.topProducts = const [],
    this.paymentMethods = const [],
    this.categorySales = const [],
    this.isLoading = false,
  });

  AnalyticsState copyWith({
    AnalyticsSummary? summary,
    List<ChartDataPoint>? salesTrend,
    List<ChartDataPoint>? topProducts,
    List<PaymentMethodData>? paymentMethods,
    List<CategorySalesData>? categorySales,
    bool? isLoading,
  }) {
    return AnalyticsState(
      summary: summary ?? this.summary,
      salesTrend: salesTrend ?? this.salesTrend,
      topProducts: topProducts ?? this.topProducts,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      categorySales: categorySales ?? this.categorySales,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;
  AnalyticsDateFilter _currentFilter = AnalyticsDateFilter.today;

  AnalyticsNotifier(this._ref)
    : super(AnalyticsState(summary: AnalyticsSummary.empty())) {
    refresh();
  }

  void refresh() {
    _calculateAnalytics();
  }

  void setFilter(AnalyticsDateFilter filter) {
    _currentFilter = filter;
    _calculateAnalytics();
  }

  void _calculateAnalytics() {
    state = state.copyWith(isLoading: true);

    final invoices = _ref.read(invoiceProvider);
    final products = _ref.read(productProvider);
    final categories = _ref.read(categoryProvider);
    final customersAsync = _ref.read(customerProvider);

    // We handle the AsyncValue for customers
    final customers = customersAsync.asData?.value ?? [];

    // Filter invoices based on selected date range
    final filteredInvoices = _filterInvoices(invoices, _currentFilter);

    // Calculate Summary
    final totalSales = filteredInvoices.fold(
      0.0,
      (sum, item) => sum + item.final_amount,
    );

    // Profit calculation - assuming a fixed 20% margin if profit not explicitly stored per item
    // In a real app, this would be (final_amount - total_cost)
    final totalProfit = totalSales * 0.25;

    final totalOrders = filteredInvoices.length;
    final totalCustomersCount = customers.length;
    final totalReceivable = customers.fold(
      0.0,
      (sum, item) =>
          sum + (item.remainingBalance > 0 ? item.remainingBalance : 0),
    );

    final summary = AnalyticsSummary(
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalOrders: totalOrders,
      totalCustomers: totalCustomersCount,
      totalReceivable: totalReceivable,
    );

    // 1. Sales Trend (Line Chart Data)
    final salesTrend = _calculateSalesTrend(invoices, _currentFilter);

    // 2. Top Products (Bar Chart Data)
    final topProducts = _calculateTopProducts(filteredInvoices);

    // 3. Payment Methods (Pie Chart Data)
    final paymentMethods = _calculatePaymentMethods(filteredInvoices);

    // 4. Category Sales (Horizontal Bar Data)
    final categorySales = _calculateCategorySales(
      filteredInvoices,
      products,
      categories,
    );

    state = state.copyWith(
      summary: summary,
      salesTrend: salesTrend,
      topProducts: topProducts,
      paymentMethods: paymentMethods,
      categorySales: categorySales,
      isLoading: false,
    );
  }

  List<dynamic> _filterInvoices(
    List<dynamic> invoices,
    AnalyticsDateFilter filter,
  ) {
    final now = DateTime.now();
    return invoices.where((inv) {
      final date = inv.date.toLocal();
      if (filter == AnalyticsDateFilter.today) {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else if (filter == AnalyticsDateFilter.week) {
        final weekAgo = now.subtract(const Duration(days: 7));
        return date.isAfter(weekAgo);
      } else {
        return date.year == now.year && date.month == now.month;
      }
    }).toList();
  }

  List<ChartDataPoint> _calculateSalesTrend(
    List<dynamic> invoices,
    AnalyticsDateFilter filter,
  ) {
    final now = DateTime.now();
    final Map<String, double> groupedSales = {};

    if (filter == AnalyticsDateFilter.week) {
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = "${d.day}/${d.month}";
        groupedSales[key] = 0;
      }
      for (var inv in invoices) {
        final date = inv.date.toLocal();
        final key = "${date.day}/${date.month}";
        if (groupedSales.containsKey(key)) {
          groupedSales[key] = groupedSales[key]! + inv.final_amount;
        }
      }
    } else {
      // Monthly or Today (simplified)
      for (var inv in invoices) {
        final date = inv.date.toLocal();
        final key = "${date.day}/${date.month}";
        groupedSales[key] = (groupedSales[key] ?? 0) + inv.final_amount;
      }
    }

    return groupedSales.entries
        .map((e) => ChartDataPoint(e.key, e.value))
        .toList();
  }

  List<ChartDataPoint> _calculateTopProducts(List<dynamic> invoices) {
    final Map<String, double> productTotals = {};
    for (var inv in invoices) {
      for (var item in inv.items) {
        productTotals[item.name] =
            (productTotals[item.name] ?? 0) + item.subtotal;
      }
    }
    final sorted = productTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => ChartDataPoint(e.key, e.value)).toList();
  }

  List<PaymentMethodData> _calculatePaymentMethods(List<dynamic> invoices) {
    final Map<String, double> methodTotals = {};
    double total = 0;
    for (var inv in invoices) {
      final method = inv.payment_mode;
      methodTotals[method] = (methodTotals[method] ?? 0) + inv.final_amount;
      total += inv.final_amount;
    }

    if (total == 0) return [];

    return methodTotals.entries
        .map(
          (e) => PaymentMethodData(
            method: e.key,
            amount: e.value,
            percentage: (e.value / total) * 100,
          ),
        )
        .toList();
  }

  List<CategorySalesData> _calculateCategorySales(
    List<dynamic> invoices,
    List<dynamic> products,
    List<dynamic> categories,
  ) {
    final Map<String, double> catTotals = {};

    // Map category ID to name
    final Map<String, String> catIdToName = {
      for (var c in categories) c.id: c.name,
    };

    // Map product name to category name for efficiency
    final Map<String, String> prodToCatName = {};
    for (var p in products) {
      prodToCatName[p.name] = catIdToName[p.category_id] ?? 'Uncategorized';
    }

    for (var inv in invoices) {
      for (var item in inv.items) {
        final categoryName = prodToCatName[item.name] ?? 'Uncategorized';
        catTotals[categoryName] =
            (catTotals[categoryName] ?? 0) + item.subtotal;
      }
    }

    return catTotals.entries
        .map((e) => CategorySalesData(e.key, e.value))
        .toList();
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
      // Watch dependencies so we refresh when data changes
      ref.watch(invoiceProvider);
      ref.watch(productProvider);
      ref.watch(categoryProvider);
      ref.watch(customerProvider);

      return AnalyticsNotifier(ref);
    });
