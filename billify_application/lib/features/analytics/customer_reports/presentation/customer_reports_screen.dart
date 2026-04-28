import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/features/analytics/customer_reports/models/customer_report_model.dart';
import 'package:billify/features/analytics/customer_reports/providers/customer_reports_provider.dart';
import 'package:billify/features/analytics/customer_reports/services/customer_report_export_service.dart';
import 'package:billify/presentation/customers/customer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerReportsScreen extends ConsumerWidget {
  const CustomerReportsScreen({super.key});

  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(customerReportsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? _buildError(state.error!)
          : _buildContent(context, ref, state),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    CustomerReportsState state,
  ) {
    return Column(
      children: [
        _buildSummaryHeader(context, state.summary),
        _buildControlBar(context, ref, state),
        const Divider(height: 1),
        Expanded(child: _buildCustomerList(context, state.customers)),
      ],
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    CustomerReportSummary summary,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Receivables',
              value: '₹${summary.totalReceivable.toStringAsFixed(0)}',
              icon: Icons.arrow_downward_rounded,
              color: Colors.redAccent,
              subtitle: 'You will get',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'Payables',
              value: '₹${summary.totalPayable.toStringAsFixed(0)}',
              icon: Icons.arrow_upward_rounded,
              color: Colors.green,
              subtitle: 'You will give',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'Customers',
              value: '${summary.totalCustomers}',
              icon: Icons.people_outline,
              color: AppTheme.primaryTeal,
              subtitle: 'Total',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(
    BuildContext context,
    WidgetRef ref,
    CustomerReportsState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) =>
                  ref.read(customerReportsProvider.notifier).updateSearch(val),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            tooltip: 'Download Report',
            onSelected: (val) {
              if (val == 'pdf') CustomerReportExportService.exportToPdf(state);
              if (val == 'excel')
                CustomerReportExportService.exportToExcel(state);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('PDF Ledger'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Excel Sheet'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                ),
              ),
              child: const Icon(Icons.download, color: AppTheme.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(
    BuildContext context,
    List<CustomerReportItem> customers,
  ) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No customers found.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, index) {
        final c = customers[index];
        final balance = c.remainingBalance;
        final isReceivable = balance > 0;
        final isPayable = balance < 0;
        final balanceColor = isReceivable
            ? Colors.redAccent
            : (isPayable ? Colors.green : Colors.grey);
        final balanceLabel = isReceivable
            ? 'YOU GET'
            : (isPayable ? 'YOU GIVE' : 'SETTLED');

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: c.id),
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryTeal.withOpacity(0.15),
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            c.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.phoneNumber,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  _miniChip(
                    'Billed: ₹${c.totalBilled.toStringAsFixed(0)}',
                    Colors.blue.withOpacity(0.12),
                    Colors.blue,
                  ),
                  _miniChip(
                    'Paid: ₹${c.totalPaid.toStringAsFixed(0)}',
                    Colors.green.withOpacity(0.12),
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: balanceColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: balanceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  balanceLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ),
            ],
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _miniChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Separate summary card widget with fixed height ──────────────────────────
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
