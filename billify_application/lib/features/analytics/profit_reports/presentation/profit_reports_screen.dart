import 'package:billify_application/features/analytics/profit_reports/providers/profit_reports_provider.dart';
import 'package:billify_application/features/analytics/profit_reports/presentation/widgets/profit_summary_card.dart';
import 'package:billify_application/features/analytics/profit_reports/presentation/widgets/profit_filter_bar.dart';
import 'package:billify_application/features/analytics/profit_reports/presentation/widgets/profit_chart.dart';
import 'package:billify_application/features/analytics/profit_reports/presentation/widgets/profit_list_item.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/data/models/user_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfitReportsScreen extends ConsumerWidget {
  const ProfitReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    
    // Permission Check
    if (!auth.hasPermission(PermissionModule.analytics, PermissionAction.view)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profit Reports')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Access Denied', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('You do not have permission to view profit reports.'),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(profitReportsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profit Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(profitReportsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          const ProfitFilterBar(),
          Expanded(
            child: state.isLoading && state.summary.totalProfit == 0
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ref.read(profitReportsProvider.notifier).refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfitSummaryCards(summary: state.summary),
                          const SizedBox(height: 24),
                          
                          _buildSectionTitle(context, 'Profit Trend'),
                          const SizedBox(height: 12),
                          _buildChartCard(context, ProfitTrendChart(data: state.trend)),
                          const SizedBox(height: 24),

                          _buildSectionTitle(context, 'Most Profitable Products'),
                          const SizedBox(height: 12),
                          if (state.topProducts.isEmpty)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No product data available'),
                            ))
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.topProducts.length,
                              itemBuilder: (context, index) {
                                return ProfitListItem(data: state.topProducts[index]);
                              },
                            ),
                          const SizedBox(height: 100), // Bottom padding
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChartCard(BuildContext context, Widget chart) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: chart,
    );
  }
}
