import 'package:billify/data/models/user_permission.dart';
import 'package:billify/features/analytics/khata_reports/presentation/widgets/khata_chart.dart';
import 'package:billify/features/analytics/khata_reports/presentation/widgets/khata_filter_bar.dart';
import 'package:billify/features/analytics/khata_reports/presentation/widgets/khata_list_item.dart';
import 'package:billify/features/analytics/khata_reports/presentation/widgets/khata_summary_card.dart';
import 'package:billify/features/analytics/khata_reports/providers/khata_reports_provider.dart';
import 'package:billify/presentation/analytics/widgets/analytics_widgets.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class KhataReportsScreen extends ConsumerWidget {
  const KhataReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(khataReportsProvider);
    final notifier = ref.read(khataReportsProvider.notifier);
    final authState = ref.watch(authProvider);

    // Permission guard
    if (!authState.hasPermission(
      PermissionModule.analytics,
      PermissionAction.view,
    )) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to view Khata reports.'),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => notifier.refresh(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KhataFilterBar(),

              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null)
                _ErrorState(
                  error: state.error!,
                  onRetry: () => notifier.refresh(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Summary Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          KhataSummaryCard(
                            title: 'Total Receivable',
                            value: currencyFormat.format(
                              state.summary.totalReceivable,
                            ),
                            icon: Icons.account_balance_wallet_outlined,
                            color: Colors.redAccent,
                          ),
                          KhataSummaryCard(
                            title: 'Total Received',
                            value: currencyFormat.format(
                              state.summary.totalReceived,
                            ),
                            icon: Icons.payments_outlined,
                            color: Colors.green,
                          ),
                          KhataSummaryCard(
                            title: 'Due Customers',
                            value: '${state.summary.customersWithDue}',
                            icon: Icons.people_outline,
                            color: Colors.orange,
                            isCurrency: false,
                          ),
                          KhataSummaryCard(
                            title: 'Avg Due',
                            value: currencyFormat.format(
                              state.summary.avgDueAmount,
                            ),
                            icon: Icons.trending_up,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Charts Section
                      // ChartContainer(
                      //   title: 'Due Amount Trends',
                      //   chart: KhataDueTrendsChart(points: state.paymentTrends.trend),
                      // ),
                      const SizedBox(height: 16),

                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: ChartContainer(
                      //         title: 'Top Due Customers',
                      //         chart: KhataTopDueChart(customers: state.topDueCustomers),
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      // const SizedBox(height: 20),

                      // Search and List
                      AnalyticsSection(
                        title: 'Customer Due List',
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (val) => notifier.updateSearch(val),
                              decoration: InputDecoration(
                                hintText: 'Search by name or phone...',
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (state.filteredDueList.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No customers found with due balance.',
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.filteredDueList.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = state.filteredDueList[index];
                                  return KhataListItem(
                                    item: item,
                                    onTap: () {
                                      // Navigation to ledger detail could go here
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Error: $error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
