import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/presentation/analytics/widgets/analytics_widgets.dart';
import 'package:billify_application/presentation/home/widgets/dashboard_components.dart';
import 'package:billify_application/providers/analytics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final notifier = ref.read(analyticsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Business Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const _LoadingShimmer()
          : RefreshIndicator(
              onRefresh: () async => notifier.refresh(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // _buildDateFilter(context, ref),
                    // _buildSummaryCards(state),
                    // _buildCharts(state),
                    _buildReportsList(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateFilter(BuildContext context, WidgetRef ref) {
    // Basic date filter implementation
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Insights Overview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          // Toggle filter simplified for dashboard view
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                _FilterButton(label: 'Today', isSelected: true, onTap: () {}),
                _FilterButton(label: 'Week', isSelected: false, onTap: () {}),
                _FilterButton(label: 'Month', isSelected: false, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2.2,
            child: Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    title: 'Total Sales',
                    value: '₹${state.summary.totalSales.toStringAsFixed(0)}',
                    icon: Icons.show_chart,
                    colors: const [AppTheme.primaryTeal, Colors.teal],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Profit',
                    value: '₹${state.summary.totalProfit.toStringAsFixed(0)}',
                    icon: Icons.auto_graph,
                    colors: const [Colors.green, Colors.greenAccent],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // AspectRatio(
          //   aspectRatio: 2.8,
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: AnalyticsCard(
          //           title: 'Orders',
          //           value: state.summary.totalOrders.toString(),
          //           icon: Icons.receipt_long,
          //           colors: const [Colors.blue, Colors.lightBlue],
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: AnalyticsCard(
          //           title: 'New Customers',
          //           value: state.summary.totalCustomers.toString(),
          //           icon: Icons.person_add,
          //           colors: const [Colors.orange, Colors.amber],
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: AnalyticsCard(
          //           title: 'Receivable',
          //           value:
          //               '₹${state.summary.totalReceivable.toStringAsFixed(0)}',
          //           icon: Icons.account_balance_wallet,
          //           colors: const [Colors.purple, Colors.deepPurpleAccent],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildCharts(AnalyticsState state) {
  //   return Column(
  //     children: [
  //       ChartContainer(
  //         title: 'Top Products',
  //         chart: PremiumRevenueGraph(
  //           data: state.topProducts.map((e) => e.value).toList(),
  //           labels: state.topProducts.map((e) => e.label).toList(),
  //           title: '',
  //         ),
  //       ),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: ChartContainer(
  //               title: 'Payment Modes',
  //               chart: PaymentMethodPieChart(data: state.paymentMethods),
  //             ),
  //           ),
  //         ],
  //       ),
  //       ChartContainer(
  //         title: 'Category Performance',
  //         chart: CategorySalesHorizontalChart(data: state.categorySales),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildReportsList(BuildContext context) {
    final reports = [
      {
        'title': 'Sales Reports',
        'icon': Icons.point_of_sale,
        'route': '/analytics/sales',
      },
      // {
      //   'title': 'Profit Reports',
      //   'icon': Icons.trending_up,
      //   'route': '/analytics/profit',
      // },
      // {
      //   'title': 'Inventory Reports',
      //   'icon': Icons.inventory_2_outlined,
      //   'route': '/analytics/inventory',
      // },
      {
        'title': 'Customer Reports',
        'icon': Icons.people_outline,
        'route': '/analytics/customers',
      },
      {
        'title': 'Khata Reports',
        'icon': Icons.menu_book,
        'route': '/analytics/khata',
      },
      // {
      //   'title': 'Payment Reports',
      //   'icon': Icons.wallet,
      //   'route': '/analytics/payments',
      // },
    ];

    return AnalyticsSection(
      title: 'Detailed Reports',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
          itemBuilder: (context, index) {
            final report = reports[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Icon(
                report['icon'] as IconData,
                color: AppTheme.primaryTeal,
              ),
              title: Text(
                report['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).hintColor,
              ),
              onTap: () =>
                  Navigator.pushNamed(context, report['route'] as String),
            );
          },
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).hintColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
