import 'dart:convert';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/data/models/ledger_model.dart';
import 'package:billify/data/models/payment_model.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/core/services/whatsapp_service.dart';
import 'package:billify/core/services/pdf_service.dart';
import 'package:billify/presentation/customers/add_customer_bottom_sheet.dart';
import 'package:billify/presentation/customers/add_payment_screen.dart';
import 'package:billify/presentation/billing/thermal_invoice_dialog.dart';
import 'package:billify/providers/invoice_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(customerLedgerProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(ledgerAsync.value?.customer.name ?? 'Customer Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer',
            onPressed: () => _showEditBottomSheet(ledgerAsync.value?.customer),
          ),
          if (ledgerAsync.value?.customer.phoneNumber != null &&
              ledgerAsync.value!.customer.phoneNumber.isNotEmpty)
            _isSharing 
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF25D366)),
                  tooltip: 'WhatsApp Reminder',
                  onPressed: () async {
                    final customer = ledgerAsync.value!.customer;
                    final business = ref.read(businessProvider).currentBusiness;
                
                if (business == null) return;

                setState(() => _isSharing = true);
                try {
                  // Get invoices for this customer to include items in PDF
                  final allInvoices = ref.read(invoiceProvider);
                  final customerInvoices = allInvoices.where(
                    (inv) => inv.customer_id == widget.customerId
                  ).toList();

                  // Generate PDF
                  final pdfFile = await PdfService.generateCustomerLedgerPdf(
                    ledgerData: ledgerAsync.value!,
                    invoices: customerInvoices,
                    business: business,
                  );

                  // Send via WhatsApp (with PDF and Text)
                  await WhatsappService.sendBalanceReminder(
                    phone: customer.phoneNumber,
                    balance: ledgerAsync.value!.summary.remainingBalance,
                    businessName: business.name,
                    pdfFile: pdfFile,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSharing = false);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Customer',
            onPressed: () =>
                _confirmDelete(context, ledgerAsync.value?.customer),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ledger (Khata)', icon: Icon(Icons.history)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
            Tab(text: 'Basic Info', icon: Icon(Icons.info_outline)),
          ],
        ),
      ),
      body: ledgerAsync.when(
        data: (ledgerData) => TabBarView(
          controller: _tabController,
          children: [
            _buildLedgerTab(ledgerData),
            _buildPaymentsTab(ledgerData.ledger),
            _buildInfoTab(ledgerData.customer),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToAddPayment(
                  isCredit: true,
                  ledgerData: ledgerAsync.value,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'YOU GAVE ₹',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToAddPayment(
                  isCredit: false,
                  ledgerData: ledgerAsync.value,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'YOU GOT ₹',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerTab(CustomerLedger ledgerData) {
    return Column(
      children: [
        _buildSummaryCard(ledgerData.summary),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: ledgerData.ledger.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              // Show newest entries first
              final entry =
                  ledgerData.ledger[ledgerData.ledger.length - 1 - index];
              final isCredit =
                  entry.type ==
                  'credit'; // Customer owes us (Invoice or Credit)

              return ListTile(
                onTap:
                    entry.referenceInvoiceId != null ||
                        (entry.note?.contains('INV #') ?? false)
                    ? () => _viewInvoiceFromLedger(context, entry)
                    : null,
                leading: CircleAvatar(
                  backgroundColor: isCredit
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  child: Icon(
                    entry.referenceInvoiceId != null
                        ? Icons.receipt_long
                        : (isCredit
                              ? Icons.arrow_upward
                              : Icons.arrow_downward),
                    color: isCredit ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(
                  entry.note ??
                      (isCredit ? 'Credit Entry' : 'Payment Received'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(entry.createdAt ?? DateTime.now()),
                    ),
                    if (entry.referenceInvoiceId != null ||
                        (entry.note?.contains('Invoice #') ?? false) ||
                        (entry.note?.contains('INV #') ?? false))
                      const Text(
                        'Tap to view receipt',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  '₹${entry.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCredit ? Colors.red : Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(LedgerSummary summary) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Total Credit',
                '₹${summary.totalCredit}',
                Colors.red,
              ),
              _buildSummaryItem(
                'Total Debit',
                '₹${summary.totalDebit}',
                Colors.green,
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remaining Balance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${summary.remainingBalance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: summary.remainingBalance >= 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
          ),
          Text(
            summary.remainingBalance >= 0
                ? 'Customer owes you'
                : 'You owe customer',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(List<Payment> payments) {
    final list = payments.where((p) => p.type == 'debit').toList();
    if (list.isEmpty)
      return const Center(child: Text('No payments recorded yet.'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return ListTile(
          leading: const Icon(Icons.payment, color: Colors.green),
          title: Text('Received via ${p.paymentMethod}'),
          subtitle: Text(
            DateFormat('dd MMM yyyy').format(p.createdAt ?? DateTime.now()),
          ),
          trailing: Text(
            '₹${p.amount}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: customer.photo != null && customer.photo!.isNotEmpty
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage: MemoryImage(
                      ImageUtils.decodeBase64(customer.photo!),
                    ),
                  )
                : CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          _infoRow(Icons.person, 'Name', customer.name),
          _infoRow(Icons.phone, 'Phone', customer.phoneNumber),
          _infoRow(
            Icons.location_city,
            'City',
            customer.city ?? 'Not specified',
          ),
          _infoRow(
            Icons.account_balance,
            'Opening Balance',
            '₹${customer.openingBalance}',
          ),
          _infoRow(
            Icons.calendar_today,
            'Added On',
            DateFormat(
              'dd MMM yyyy',
            ).format(customer.createdAt ?? DateTime.now()),
          ),
        ],
      ),
    );
  }

  void _viewInvoiceFromLedger(BuildContext context, Payment entry) async {
    String? searchId;

    if (entry.referenceInvoiceId != null) {
      searchId = entry.referenceInvoiceId.toString();
    } else if (entry.note != null &&
        (entry.note!.contains('Invoice #') || entry.note!.contains('INV #'))) {
      final parts = entry.note!.split('#');
      if (parts.length > 1) searchId = parts[1].trim();
    }

    if (searchId == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching receipt details...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final invoice = await ref
          .read(invoiceProvider.notifier)
          .getInvoiceById(searchId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (invoice != null) {
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
              customerId: invoice.customer_id,
              customerType: invoice.customer_type,
              isViewOnly: true,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice details not found on server (#$searchId)'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching receipt: $e')));
      }
    }
  }

  void _showEditBottomSheet(Customer? customer) {
    if (customer == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddCustomerBottomSheet(initialCustomer: customer),
    ).then((result) {
      if (result == true) {
        ref.invalidate(customerLedgerProvider(widget.customerId));
      }
    });
  }

  void _confirmDelete(BuildContext context, Customer? customer) {
    if (customer == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This will remove all their Khata history and payments permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(customerProvider.notifier)
                    .deleteCustomer(customer.id!);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting customer: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPayment({
    required bool isCredit,
    CustomerLedger? ledgerData,
  }) {
    if (ledgerData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddPaymentScreen(customer: ledgerData.customer, isCredit: isCredit),
      ),
    ).then((_) => ref.invalidate(customerLedgerProvider(widget.customerId)));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
