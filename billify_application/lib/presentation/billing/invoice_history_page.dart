import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/presentation/billing/thermal_invoice_dialog.dart';
import 'package:billify_application/providers/invoice_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InvoiceHistoryPage extends ConsumerStatefulWidget {
  const InvoiceHistoryPage({super.key});

  @override
  ConsumerState<InvoiceHistoryPage> createState() => _InvoiceHistoryPageState();
}

class _InvoiceHistoryPageState extends ConsumerState<InvoiceHistoryPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days or similar if desired, but user said "from to", so I'll keep it null for "All"
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceProvider);
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final filterDateFormat = DateFormat('MMM dd, yyyy');

    // Filter invoices by date
    final filteredInvoices = invoices.where((invoice) {
      if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (invoice.date.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (invoice.date.isAfter(end)) return false;
      }
      return true;
    }).toList();


    return Scaffold(
      appBar: AppBar(title: const Text('Invoice History')),
      body: Column(
        children: [
          _buildFilterBar(context, filterDateFormat),
          Expanded(
            child: filteredInvoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          invoices.isEmpty
                              ? 'No invoices generated yet'
                              : 'No invoices found for selected range',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                            child: const Icon(
                              Icons.receipt_long,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          title: Text(
                            '#${invoice.id.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFormat.format(invoice.date)),
                              Row(
                                children: [
                                  Text(
                                    '${invoice.items.length} items',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'By: ${invoice.staffName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${invoice.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.print_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _viewInvoice(context, invoice),
                              ),
                            ],
                          ),
                          onTap: () => _viewInvoice(context, invoice),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.primaryTeal),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryTeal),
                    const SizedBox(width: 8),
                    Text(
                      _startDate == null ? 'From' : dateFormat.format(_startDate!),
                      style: TextStyle(fontSize: 12, color: _startDate == null ? Colors.grey : null),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('-', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.primaryTeal),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryTeal),
                    const SizedBox(width: 8),
                    Text(
                      _endDate == null ? 'To' : dateFormat.format(_endDate!),
                      style: TextStyle(fontSize: 12, color: _endDate == null ? Colors.grey : null),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.red),
              onPressed: () => setState(() {
                _startDate = null;
                _endDate = null;
              }),
            ),
        ],
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
