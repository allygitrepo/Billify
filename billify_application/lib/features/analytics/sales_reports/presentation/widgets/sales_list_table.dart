import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/invoice_model.dart';
import 'package:billify/presentation/billing/thermal_invoice_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Interactive, user-friendly card-based presentation for Recent Transactions.
class SalesListTable extends StatelessWidget {
  final List<InvoiceModel> invoices;

  const SalesListTable({super.key, required this.invoices});

  void _openInvoiceDetails(BuildContext context, InvoiceModel invoice) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (invoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Transactions Found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sales transactions for this filter period will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final isWalkin = invoice.customer_name == null ||
            invoice.customer_name!.trim().isEmpty ||
            invoice.customer_name!.toLowerCase() == 'walk-in' ||
            invoice.customer_name!.toLowerCase() == 'walkin';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openInvoiceDetails(context, invoice),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Receipt icon, Invoice ID, Date & Total Amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: AppTheme.primaryTeal,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(invoice.date.toLocal()),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${invoice.final_amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildPaymentBadge(invoice),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                    height: 1,
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),

                  // Middle Row: Customer Details & Items summary
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              isWalkin
                                  ? Icons.person_outline_rounded
                                  : Icons.person_rounded,
                              size: 16,
                              color: isWalkin
                                  ? Colors.grey
                                  : AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isWalkin
                                    ? 'Walk-in Customer'
                                    : (invoice.customer_phone != null &&
                                            invoice.customer_phone!.isNotEmpty)
                                        ? '${invoice.customer_name} • ${invoice.customer_phone}'
                                        : (invoice.customer_name ?? 'Walk-in'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isWalkin
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  color: isWalkin
                                      ? (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600)
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Item count chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${invoice.items.length} ${invoice.items.length == 1 ? 'item' : 'items'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Optional item preview if items exist
                  if (invoice.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      invoice.items
                          .map((i) =>
                              '${i.name} (x${i.quantity % 1 == 0 ? i.quantity.toInt() : i.quantity})')
                          .take(3)
                          .join(', ') +
                          (invoice.items.length > 3 ? '...' : ''),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Bottom Action Indicator
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'View Receipt',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppTheme.primaryTeal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentBadge(InvoiceModel invoice) {
    final mode = invoice.payment_mode.trim().toUpperCase();
    final isFullyPaid = invoice.paid_amount >= invoice.final_amount;

    Color badgeColor;
    Color textColor;
    String label;

    if (mode == 'KHATA' || (!isFullyPaid && invoice.paid_amount == 0)) {
      badgeColor = Colors.orange.withValues(alpha: 0.12);
      textColor = Colors.orange.shade800;
      label = 'KHATA';
    } else if (mode == 'SPLIT' || (!isFullyPaid && invoice.paid_amount > 0)) {
      badgeColor = Colors.purple.withValues(alpha: 0.12);
      textColor = Colors.purple.shade700;
      label = 'SPLIT';
    } else {
      badgeColor = Colors.green.withValues(alpha: 0.12);
      textColor = Colors.green.shade700;
      label = mode.isNotEmpty ? mode : 'PAID';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
