import 'dart:async';
import 'package:billify/core/services/ad_service.dart';
import 'package:billify/core/services/pdf_service.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/data/models/ledger_model.dart';
import 'package:billify/data/models/payment_model.dart';
import 'package:billify/presentation/billing/thermal_invoice_dialog.dart';
import 'package:billify/presentation/customers/add_customer_bottom_sheet.dart';
import 'package:billify/presentation/customers/add_payment_screen.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:billify/providers/invoice_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSharing = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _callCustomer(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      AppFeedback.showError(
        context,
        'No phone number available for this customer',
      );
      return;
    }
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.trim(),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          AppFeedback.showError(context, 'Could not launch phone dialer');
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error launching phone dialer: $e');
      }
    }
  }

  Future<void> _shareStatement(CustomerLedger? ledgerData) async {
    final customer = ledgerData?.customer;
    final business = ref.read(businessProvider).currentBusiness;

    if (customer == null || business == null || ledgerData == null) return;

    setState(() => _isSharing = true);

    await AdService.instance.showInterstitialAd(
      placement: 'share_statement',
      onDismissed: () async {
        try {
          final allInvoices = ref.read(invoiceProvider);
          final customerInvoices = allInvoices.where(
            (inv) => inv.customer_id == widget.customerId,
          ).toList();

          final pdfFile = await PdfService.generateCustomerLedgerPdf(
            ledgerData: ledgerData,
            invoices: customerInvoices,
            business: business,
          );

          await Share.shareXFiles(
            [XFile(pdfFile.path)],
            text:
                'Statement for ${customer.name}\nOutstanding Balance: ₹${ledgerData.summary.remainingBalance.toStringAsFixed(2)}',
          );
        } catch (e) {
          if (mounted) {
            AppFeedback.showError(context, e);
          }
        } finally {
          if (mounted) setState(() => _isSharing = false);
        }
      },
    );
  }

  void _showCustomerInfoSheet(BuildContext context, Customer customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Center(
                      child: customer.photo != null && customer.photo!.isNotEmpty
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: MemoryImage(
                                ImageUtils.decodeBase64(customer.photo!),
                              ),
                            )
                          : CircleAvatar(
                              radius: 40,
                              backgroundColor: isDark
                                  ? const Color(0xFF383127)
                                  : const Color(0xFFFFE0B2),
                              child: Text(
                                customer.name.isNotEmpty
                                    ? customer.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phoneNumber,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const Divider(height: 28),
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
                      'Customer Since',
                      DateFormat('dd MMM yyyy').format(
                        customer.createdAt ?? DateTime.now(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _callCustomer(customer.phoneNumber);
                            },
                            icon: const Icon(Icons.phone, color: Colors.green),
                            label: const Text('Call'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditBottomSheet(customer);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Details'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(customerLedgerProvider(widget.customerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSharing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Statement',
              onPressed: () => _shareStatement(ledgerAsync.value),
            ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            tooltip: 'Call Customer',
            onPressed: () =>
                _callCustomer(ledgerAsync.value?.customer.phoneNumber),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              final customer = ledgerAsync.value?.customer;
              if (customer == null) return;
              if (val == 'info') {
                _showCustomerInfoSheet(context, customer);
              } else if (val == 'edit') {
                _showEditBottomSheet(customer);
              } else if (val == 'delete') {
                _confirmDelete(context, customer);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 10),
                    Text('Customer Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Edit Customer'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text(
                      'Delete Customer',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ledgerAsync.when(
        data: (ledgerData) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          // Sort chronologically (oldest at top, latest at bottom like Image 2)
          final sortedEntries = List<Payment>.from(ledgerData.ledger)
            ..sort((a, b) {
              final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return dateA.compareTo(dateB);
            });

          // Calculate running due for each entry
          double runningDue = ledgerData.summary.openingBalance;
          final Map<Payment, double> dueMap = {};
          for (final entry in sortedEntries) {
            if (entry.type == 'credit') {
              runningDue += entry.amount;
            } else {
              runningDue -= entry.amount;
            }
            dueMap[entry] = runningDue;
          }

          // Group by Date formatted dd/MM/yyyy matching Image 2
          final Map<String, List<Payment>> groupedEntries = {};
          final dateFormat = DateFormat('dd/MM/yyyy');
          for (final entry in sortedEntries) {
            final dateKey = dateFormat.format(
              entry.createdAt ?? DateTime.now(),
            );
            groupedEntries.putIfAbsent(dateKey, () => []).add(entry);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Customer Profile & Outstanding Card (matching Image 2)
              _buildCustomerHeaderCard(context, ledgerData, isDark),

              // 2. Section Header: "Transaction History"
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // 3. Conversational / Chat-Style Ledger History
              Expanded(
                child: sortedEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions recorded yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use buttons below to record credit or payment',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 16, top: 4),
                        itemCount: groupedEntries.keys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateKey = groupedEntries.keys.elementAt(groupIndex);
                          final entriesForDate = groupedEntries[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Date Capsule Chip
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    dateKey,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),

                              // Bubbles for this date
                              ...entriesForDate.map(
                                (entry) => _buildTransactionBubble(
                                  context,
                                  entry,
                                  dueMap[entry] ?? 0.0,
                                  isDark,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigateToAddPayment(
                    isCredit: true,
                    ledgerData: ledgerAsync.value,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: const Text('YOU GAVE ₹'),
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
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: const Text('YOU GOT ₹'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Customer Profile & Outstanding Card (matching Image 2)
  Widget _buildCustomerHeaderCard(
    BuildContext context,
    CustomerLedger ledgerData,
    bool isDark,
  ) {
    final customer = ledgerData.customer;
    final summary = ledgerData.summary;
    final balance = summary.remainingBalance;
    final isReceivable = balance > 0;
    final isPayable = balance < 0;

    final balanceColor = isReceivable
        ? const Color(0xFFFF5252)
        : (isPayable ? const Color(0xFF4CAF50) : (isDark ? Colors.grey : Colors.grey.shade700));

    final balanceLabel = isReceivable
        ? 'Total Outstanding'
        : (isPayable ? 'Advance Paid' : 'All Settled');

    final balanceStr = '₹${balance.abs().toStringAsFixed(balance.abs() % 1 == 0 ? 0 : 2)}';

    return InkWell(
      onTap: () => _showCustomerInfoSheet(context, customer),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            customer.photo != null && customer.photo!.isNotEmpty
                ? CircleAvatar(
                    radius: 22,
                    backgroundImage: MemoryImage(
                      ImageUtils.decodeBase64(customer.photo!),
                    ),
                  )
                : CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark
                        ? const Color(0xFF383127)
                        : const Color(0xFFFFE0B2),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFFE65100),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
            const SizedBox(width: 12),

            // Name & Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        customer.phoneNumber,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Outstanding Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balanceStr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balanceLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Conversational Chat Bubble (matching Image 2)
  Widget _buildTransactionBubble(
    BuildContext context,
    Payment entry,
    double dueAfter,
    bool isDark,
  ) {
    final isCredit = entry.type == 'credit'; // True: You Gave (Red, Right), False: You Got (Green, Left)
    final timeStr = DateFormat('hh:mm a').format(
      entry.createdAt ?? DateTime.now(),
    );
    final hasInvoice = entry.referenceInvoiceId != null ||
        (entry.note?.contains('Invoice #') ?? false) ||
        (entry.note?.contains('INV #') ?? false);

    final rawNote = entry.note?.trim();
    final noteText = (rawNote != null && rawNote.isNotEmpty)
        ? rawNote
        : (isCredit ? 'DEBIT ENTRY' : 'PAYMENT');
    final methodText = entry.paymentMethod.toUpperCase();
    final subtitle = '$noteText • $methodText';

    final amountStr = '₹${entry.amount.toStringAsFixed(entry.amount % 1 == 0 ? 0 : 2)}';
    final dueStr = 'Due: ₹${dueAfter.abs().toStringAsFixed(dueAfter.abs() % 1 == 0 ? 0 : 2)}';

    if (!isCredit) {
      // ----------------------------------------------------
      // "YOU GOT" (Payment Received) - GREEN BUBBLE ON LEFT
      // ----------------------------------------------------
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
            minWidth: 190,
          ),
          margin: const EdgeInsets.only(left: 14, right: 54, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
                  : const Color(0xFFA5D6A7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Green down arrow, amount, time, optional receipt badge
              Row(
                children: [
                  const Icon(
                    Icons.arrow_downward,
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amountStr,
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (hasInvoice)
                    InkWell(
                      onTap: () => _viewInvoiceFromLedger(context, entry),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 12,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Receipt',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Note / Description & Mode
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Row 3: Status Badge
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  dueAfter <= 0 ? 'All Clear' : dueStr,
                  style: TextStyle(
                    color: dueAfter <= 0
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // ----------------------------------------------------
      // "YOU GAVE" (Credit Given) - RED BUBBLE ON RIGHT
      // ----------------------------------------------------
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
            minWidth: 190,
          ),
          margin: const EdgeInsets.only(left: 54, right: 14, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C1917) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFD32F2F).withValues(alpha: 0.5)
                  : const Color(0xFFEF9A9A),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Red up arrow, amount, time, optional invoice button
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    color: Color(0xFFFF5252),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amountStr,
                    style: const TextStyle(
                      color: Color(0xFFFF5252),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (hasInvoice)
                    InkWell(
                      onTap: () => _viewInvoiceFromLedger(context, entry),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 12,
                              color: Color(0xFFFF5252),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Invoice',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF5252),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Note / Description & Mode
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Row 3: Due Amount Badge
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  dueStr,
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
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

    unawaited(
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
      ),
    );

    try {
      final invoice = await ref
          .read(invoiceProvider.notifier)
          .getInvoiceById(searchId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (invoice != null) {
          unawaited(
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
          ),
        );
        } else {
          AppFeedback.showError(
            context,
            'Invoice details not found on server (#$searchId)',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        AppFeedback.showError(context, e);
      }
    }
  }

  void _showEditBottomSheet(Customer? customer) {
    if (customer == null) return;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AddCustomerBottomSheet(initialCustomer: customer),
        ),
      ),
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
                  AppFeedback.showSuccess(
                    context,
                    'Customer deleted successfully',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, e);
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
}
