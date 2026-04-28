import 'package:billify/data/models/invoice_model.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesListTable extends StatelessWidget {
  final List<InvoiceModel> invoices;

  const SalesListTable({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No transactions found for this period'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          fontSize: 13,
        ),
        dataTextStyle: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        columns: const [
          DataColumn(label: Text('Invoice #')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Customer Details')),
          DataColumn(label: Text('Items (Qty)')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Method')),
        ],
        rows: invoices.map((invoice) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  invoice.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
              DataCell(Text(DateFormat('dd MMM, yyyy').format(invoice.date))),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      invoice.customer_name ?? 'Walk-in',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (invoice.customer_phone != null &&
                        invoice.customer_phone!.isNotEmpty)
                      Text(
                        invoice.customer_phone!,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              DataCell(
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: invoice.items
                        .map(
                          (item) => Text(
                            "${item.name} (${item.quantity})",
                            style: const TextStyle(fontSize: 10),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '₹${invoice.final_amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(_buildStatusChip(invoice.payment_mode)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.primaryTeal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
