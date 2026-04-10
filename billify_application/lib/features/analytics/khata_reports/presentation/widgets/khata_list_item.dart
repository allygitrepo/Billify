import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/features/analytics/khata_reports/models/khata_report_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KhataListItem extends StatelessWidget {
  final KhataDueReportItem item;
  final VoidCallback onTap;

  const KhataListItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM, yyyy');

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
        child: Text(
          item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.phoneNumber, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          if (item.lastPaymentDate != null)
            Text(
              'Last payment: ${dateFormat.format(item.lastPaymentDate!)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          if (item.creditLimit != null)
            Text(
              'Limit: ${currencyFormat.format(item.creditLimit)}',
              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(item.totalDue),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
          ),
          const Text(
            'TOTAL DUE',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
