import 'package:billify/features/analytics/sales_reports/presentation/widgets/sales_filter_bar.dart';
import 'package:billify/features/analytics/sales_reports/presentation/widgets/sales_summary_cards.dart';
import 'package:billify/features/analytics/sales_reports/presentation/widgets/top_products_list.dart';
import 'package:billify/features/analytics/sales_reports/presentation/widgets/sales_list_table.dart';
import 'package:billify/features/analytics/sales_reports/providers/sales_reports_provider.dart';
import 'package:billify/presentation/analytics/widgets/analytics_widgets.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/features/analytics/sales_reports/services/report_export_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesReportsScreen extends ConsumerWidget {
  const SalesReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesReportsProvider);
    final notifier = ref.read(salesReportsProvider.notifier);
    final authState = ref.watch(authProvider);

    // Permission guard
    if (!authState.hasPermission(
      PermissionModule.analytics,
      PermissionAction.view,
    )) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to view sales reports.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sales Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showExportOptions(context, ref),
            tooltip: 'Export Report',
          ),
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
              // Sticky Filter Bar effect using Sliver or simple row
              const SalesFilterBar(),

              if (state.isLoading)
                const _LoadingShimmer()
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
                      SalesSummaryCards(summary: state.summary),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ChartContainer(
                              title: 'Top Products',
                              chart: TopProductsList(
                                products: state.topProducts,
                              ),
                            ),
                          ),
                        ],
                      ),

                      AnalyticsSection(
                        title: 'Recent Transactions',
                        child: SalesListTable(invoices: state.invoices),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Report As',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Document'),
              onTap: () {
                Navigator.pop(context);
                final state = ref.read(salesReportsProvider);
                ReportExportService.exportToPdf(state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel Spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                final state = ref.read(salesReportsProvider);
                ReportExportService.exportToExcel(state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Print Report'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator()),
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
          Text('Error: $error', style: const TextStyle(color: Colors.red)),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
