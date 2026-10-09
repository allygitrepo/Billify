import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/invoice_model.dart';
import 'package:billify/presentation/billing/thermal_invoice_dialog.dart';
import 'package:billify/providers/invoice_provider.dart';
import 'package:billify/presentation/widgets/app_banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billify/providers/customer_provider.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceProvider);
    final customers = ref.watch(customerProvider).value ?? [];
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final filterDateFormat = DateFormat('MMM dd, yyyy');

    // Filter invoices by date
    final filteredInvoices = invoices.where((invoice) {
      if (_startDate != null) {
        final start = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        if (invoice.date.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        if (invoice.date.isAfter(end)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice History'),
            Text(
              filteredInvoices.length == invoices.length
                  ? '${filteredInvoices.length} ${filteredInvoices.length == 1 ? 'invoice' : 'invoices'}'
                  : '${filteredInvoices.length} of ${invoices.length} invoices',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7) ??
                    Colors.grey,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: AppBannerAd(),
      ),
      body: Column(
        children: [
          _buildFilterBar(context, filterDateFormat),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredInvoices.length} ${filteredInvoices.length == 1 ? 'Invoice found' : 'Invoices found'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                if (filteredInvoices.isNotEmpty)
                  Text(
                    'Total: ₹${filteredInvoices.fold<double>(0.0, (sum, inv) => sum + inv.final_amount).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
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
                      final customer = customers
                          .where((c) => c.id == invoice.customer_id)
                          .firstOrNull;
                      final isWalkin =
                          invoice.customer_type == 'WALKIN' || customer == null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _viewInvoice(context, invoice),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      AppTheme.primaryTeal.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: AppTheme.primaryTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'INV #${invoice.id.toUpperCase()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(
                                          invoice.date.toLocal(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color ??
                                              Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isWalkin
                                                ? Icons.person_outline
                                                : Icons.person,
                                            size: 13,
                                            color: isWalkin
                                                ? Colors.grey
                                                : AppTheme.primaryTeal,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              isWalkin
                                                  ? 'Walk-in Customer'
                                                  : customer.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isWalkin
                                                    ? Colors.grey
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                fontWeight: isWalkin
                                                    ? FontWeight.normal
                                                    : FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${invoice.final_amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.primaryTeal,
                                      ),
                                    ),
                                    if (invoice.previous_balance > 0) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        'Due: ₹${invoice.totalDue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (invoice.paid_amount >=
                                                    invoice.final_amount)
                                                ? Colors.green.withOpacity(0.12)
                                                : Colors.red.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (invoice.paid_amount >=
                                                invoice.final_amount)
                                            ? 'PAID'
                                            : 'KHATA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              (invoice.paid_amount >=
                                                      invoice.final_amount)
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primaryTeal,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _startDate == null
                          ? 'From'
                          : dateFormat.format(_startDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _startDate == null ? Colors.grey : null,
                      ),
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
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primaryTeal,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _endDate == null ? 'To' : dateFormat.format(_endDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _endDate == null ? Colors.grey : null,
                      ),
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
        subtotal: invoice.total_amount,
        taxAmount: invoice.tax_amount,
        gstAmount: invoice.gst_amount,
        total: invoice.final_amount,
        invoiceId: invoice.id,
        invoiceDate: invoice.date,
        initialPaidAmount: invoice.paid_amount,
        initialPaymentMode: invoice.payment_mode,
        customerId: invoice.customer_id,
        customerType: invoice.customer_type,
        invoice: invoice,
        previousBalance: invoice.previous_balance,
        isViewOnly: true,
      ),
    );
  }
}
