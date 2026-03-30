import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/presentation/billing/thermal_invoice_dialog.dart';
import 'package:billify_application/providers/invoice_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InvoiceHistoryPage extends ConsumerWidget {
  const InvoiceHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceProvider);
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
      ),
      body: invoices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No invoices generated yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                      child: const Icon(Icons.receipt_long, color: AppTheme.primaryTeal),
                    ),
                    title: Text(
                      'Invoice #${invoice.id.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateFormat.format(invoice.date)),
                        Text('${invoice.items.length} items', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${invoice.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.print_outlined, size: 20, color: Colors.grey),
                          onPressed: () => _viewInvoice(context, invoice),
                        ),
                      ],
                    ),
                    onTap: () => _viewInvoice(context, invoice),
                  ),
                );
              },
            ),
    );
  }

  void _viewInvoice(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => ThermalInvoiceDialog(
        items: invoice.items,
        business: invoice.business,
        subtotal: invoice.subtotal,
        taxAmount: invoice.taxAmount,
        gstAmount: invoice.gstAmount,
        total: invoice.total,
        invoiceId: invoice.id,
      ),
    );
  }
}
