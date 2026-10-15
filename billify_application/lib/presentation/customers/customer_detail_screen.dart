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

class StatementTransaction {
  final String id;
  final DateTime date;
  final String title;
  final String paymentMethod;
  final String? note;
  final int? referenceInvoiceId;
  final String? invoiceNumber;
  final Payment? creditPayment;
  final Payment? debitPayment;

  final double balanceBefore;
  final double billAmount;
  final double paidAmount;
  final double balanceAfter;

  StatementTransaction({
    required this.id,
    required this.date,
    required this.title,
    required this.paymentMethod,
    this.note,
    this.referenceInvoiceId,
    this.invoiceNumber,
    this.creditPayment,
    this.debitPayment,
    required this.balanceBefore,
    required this.billAmount,
    required this.paidAmount,
    required this.balanceAfter,
  });

  bool get isInvoice =>
      referenceInvoiceId != null ||
      invoiceNumber != null ||
      (creditPayment?.note?.contains('Invoice #') ?? false) ||
      (creditPayment?.note?.contains('INV #') ?? false);
}

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
  String _viewMode = 'chat'; // 'chat', 'statement'

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

          // Build unified statement transactions (Bank Statement style)
          final statementTransactions = _buildStatementTransactions(
            sortedEntries,
            ledgerData.summary.openingBalance,
          );

          // Calculate running due for individual entries (for Chat View)
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

          // Group by Date formatted dd/MM/yyyy
          final dateFormat = DateFormat('dd/MM/yyyy');
          final Map<String, List<Payment>> groupedEntries = {};
          for (final entry in sortedEntries) {
            final dateKey = dateFormat.format(
              entry.createdAt ?? DateTime.now(),
            );
            groupedEntries.putIfAbsent(dateKey, () => []).add(entry);
          }

          final Map<String, List<StatementTransaction>> groupedStatement = {};
          for (final tx in statementTransactions) {
            final dateKey = dateFormat.format(tx.date);
            groupedStatement.putIfAbsent(dateKey, () => []).add(tx);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Customer Profile & Outstanding Card
              _buildCustomerHeaderCard(context, ledgerData, isDark),

              // 2. Section Header: "Statement History" with 3-Way Mode Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statement History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleButton(
                            label: 'Chat',
                            icon: Icons.chat_bubble_outline,
                            isSelected: _viewMode == 'chat',
                            onTap: () => setState(() => _viewMode = 'chat'),
                            isDark: isDark,
                          ),
                          _buildToggleButton(
                            label: 'Statement',
                            icon: Icons.view_agenda_outlined,
                            isSelected: _viewMode == 'statement',
                            onTap: () => setState(() => _viewMode = 'statement'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Transactions List based on _viewMode
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
                    : _viewMode == 'chat'
                        ? ListView.builder(
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
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(bottom: 16, top: 4),
                                itemCount: groupedStatement.keys.length,
                                itemBuilder: (context, groupIndex) {
                                  final dateKey = groupedStatement.keys.elementAt(groupIndex);
                                  final txList = groupedStatement[dateKey]!;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Date Capsule Chip
                                      Center(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 8),
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

                                      // Statement Cards for this date
                                      ...txList.map(
                                        (tx) => _buildStatementCard(
                                          context,
                                          tx,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
            const SizedBox(height: 10),
            // Mini 3-Item Bank Statement Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderSummaryItem(
                    'Total Bills',
                    _formatCurrency(summary.totalCredit),
                    const Color(0xFFFF5252),
                    isDark,
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                  _buildHeaderSummaryItem(
                    'Total Paid',
                    _formatCurrency(summary.totalDebit),
                    const Color(0xFF4CAF50),
                    isDark,
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                  _buildHeaderSummaryItem(
                    isReceivable ? 'Net Due' : (isPayable ? 'Advance' : 'Settled'),
                    _formatCurrency(balance),
                    balanceColor,
                    isDark,
                  ),
                ],
              ),
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

    final bool isDue = dueAfter > 0.001;
    final bool isAdvance = dueAfter < -0.001;
    final String formattedDue = dueAfter.abs().toStringAsFixed(
      dueAfter.abs() % 1 == 0 ? 0 : 2,
    );
    final String statusText = isDue
        ? 'Due: ₹$formattedDue'
        : (isAdvance ? 'Advance: ₹$formattedDue' : 'All Clear');
    final Color statusColor = isDue
        ? const Color(0xFFFF5252)
        : const Color(0xFF4CAF50);

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
                  statusText,
                  style: TextStyle(
                    color: statusColor,
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
                  statusText,
                  style: TextStyle(
                    color: statusColor,
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

  void _viewInvoiceFromLedger(BuildContext context, Payment entry) {
    String? searchId;

    if (entry.referenceInvoiceId != null) {
      searchId = entry.referenceInvoiceId.toString();
    } else if (entry.note != null &&
        (entry.note!.contains('Invoice #') || entry.note!.contains('INV #'))) {
      final parts = entry.note!.split('#');
      if (parts.length > 1) searchId = parts[1].trim();
    }

    if (searchId != null) {
      _fetchAndShowInvoiceDialog(context, searchId);
    }
  }

  void _viewInvoiceFromStatement(
    BuildContext context,
    StatementTransaction tx,
  ) {
    String? searchId;
    if (tx.referenceInvoiceId != null) {
      searchId = tx.referenceInvoiceId.toString();
    } else if (tx.invoiceNumber != null) {
      searchId = tx.invoiceNumber;
    } else if (tx.note != null &&
        (tx.note!.contains('Invoice #') || tx.note!.contains('INV #'))) {
      final parts = tx.note!.split('#');
      if (parts.length > 1) searchId = parts[1].trim();
    }

    if (searchId != null) {
      _fetchAndShowInvoiceDialog(context, searchId);
    }
  }

  void _fetchAndShowInvoiceDialog(BuildContext context, String searchId) async {
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

  // ----------------------------------------------------
  // STATEMENT & PASSBOOK VIEW BUILDERS
  // ----------------------------------------------------

  String _formatCurrency(double amount) {
    final absVal = amount.abs();
    return '₹${absVal.toStringAsFixed(absVal % 1 == 0 ? 0 : 2)}';
  }

  Widget _buildHeaderSummaryItem(
    String label,
    String value,
    Color valueColor,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractInvoiceNumber(String? note) {
    if (note == null || note.isEmpty) return null;
    final regex = RegExp(
      r'(?:Invoice\s*#|INV\s*#|#)\s*([A-Za-z0-9\/\-_]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(note);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    return null;
  }

  List<StatementTransaction> _buildStatementTransactions(
    List<Payment> sortedEntries,
    double openingBalance,
  ) {
    final List<StatementTransaction> transactions = [];
    double runningBalance = openingBalance;
    final Set<int> consumedIndices = {};

    for (int i = 0; i < sortedEntries.length; i++) {
      if (consumedIndices.contains(i)) continue;

      final entry = sortedEntries[i];
      Payment? matchingPayment;
      int? matchingIndex;

      final refId = entry.referenceInvoiceId;
      final invNumber = _extractInvoiceNumber(entry.note);

      if (refId != null || invNumber != null) {
        for (int j = i + 1; j < sortedEntries.length; j++) {
          if (consumedIndices.contains(j)) continue;
          final other = sortedEntries[j];

          final sameRef = refId != null && other.referenceInvoiceId == refId;
          final otherInv = _extractInvoiceNumber(other.note);
          final sameInv = invNumber != null &&
              otherInv != null &&
              invNumber.toLowerCase() == otherInv.toLowerCase();

          if ((sameRef || sameInv) && entry.type != other.type) {
            final diff = (other.createdAt ?? DateTime.now())
                .difference(entry.createdAt ?? DateTime.now())
                .abs();
            if (diff.inMinutes <= 15) {
              matchingPayment = other;
              matchingIndex = j;
              break;
            }
          }
        }
      }

      if (matchingPayment != null && matchingIndex != null) {
        consumedIndices.add(i);
        consumedIndices.add(matchingIndex);

        final creditEntry = entry.type == 'credit' ? entry : matchingPayment;
        final debitEntry = entry.type == 'debit' ? entry : matchingPayment;

        final balanceBefore = runningBalance;
        final billAmount = creditEntry.amount;
        final paidAmount = debitEntry.amount;
        final balanceAfter = balanceBefore + billAmount - paidAmount;
        runningBalance = balanceAfter;

        final method = (creditEntry.paymentMethod.isNotEmpty &&
                creditEntry.paymentMethod.toUpperCase() != 'CASH')
            ? creditEntry.paymentMethod
            : (debitEntry.paymentMethod.isNotEmpty
                ? debitEntry.paymentMethod
                : 'Cash');

        final title = invNumber != null ? 'Invoice #$invNumber' : 'Invoice';

        transactions.add(StatementTransaction(
          id: 'grouped_${creditEntry.id}_${debitEntry.id}',
          date: creditEntry.createdAt ?? debitEntry.createdAt ?? DateTime.now(),
          title: title,
          paymentMethod: method.toUpperCase(),
          note: creditEntry.note ?? debitEntry.note,
          referenceInvoiceId:
              creditEntry.referenceInvoiceId ?? debitEntry.referenceInvoiceId,
          invoiceNumber: invNumber ?? _extractInvoiceNumber(debitEntry.note),
          creditPayment: creditEntry,
          debitPayment: debitEntry,
          balanceBefore: balanceBefore,
          billAmount: billAmount,
          paidAmount: paidAmount,
          balanceAfter: balanceAfter,
        ));
      } else {
        consumedIndices.add(i);

        final balanceBefore = runningBalance;
        double billAmount = 0.0;
        double paidAmount = 0.0;

        if (entry.type == 'credit') {
          billAmount = entry.amount;
        } else {
          paidAmount = entry.amount;
        }

        final balanceAfter = balanceBefore + billAmount - paidAmount;
        runningBalance = balanceAfter;

        String title;
        if (entry.type == 'credit') {
          final inv = _extractInvoiceNumber(entry.note);
          title = inv != null
              ? 'Invoice #$inv'
              : (entry.note?.isNotEmpty == true
                  ? entry.note!
                  : 'Debit Entry');
        } else {
          title = entry.note?.isNotEmpty == true
              ? entry.note!
              : 'Payment Received';
        }

        transactions.add(StatementTransaction(
          id: 'single_${entry.id ?? i}',
          date: entry.createdAt ?? DateTime.now(),
          title: title,
          paymentMethod: entry.paymentMethod.toUpperCase(),
          note: entry.note,
          referenceInvoiceId: entry.referenceInvoiceId,
          invoiceNumber: _extractInvoiceNumber(entry.note),
          creditPayment: entry.type == 'credit' ? entry : null,
          debitPayment: entry.type == 'debit' ? entry : null,
          balanceBefore: balanceBefore,
          billAmount: billAmount,
          paidAmount: paidAmount,
          balanceAfter: balanceAfter,
        ));
      }
    }

    return transactions;
  }

  Widget _buildStatementCard(
    BuildContext context,
    StatementTransaction tx,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final dateStr = dateFormat.format(tx.date);
    final timeStr = timeFormat.format(tx.date);

    final bool isDue = tx.balanceAfter > 0.001;
    final bool isAdvance = tx.balanceAfter < -0.001;

    final balanceLabel = isDue
        ? 'Due'
        : (isAdvance ? 'Advance' : 'All Clear');
    final balanceColor = isDue
        ? const Color(0xFFFF5252)
        : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Header (Icon, Title, Payment Method Badge, Time, View Bill Button)
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tx.billAmount > 0 && tx.paidAmount > 0
                      ? const Color(0xFF2196F3).withValues(alpha: 0.15)
                      : (tx.billAmount > 0
                          ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.15)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.billAmount > 0 && tx.paidAmount > 0
                      ? Icons.receipt_long
                      : (tx.billAmount > 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                  size: 16,
                  color: tx.billAmount > 0 && tx.paidAmount > 0
                      ? const Color(0xFF2196F3)
                      : (tx.billAmount > 0
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF4CAF50)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.paymentMethod,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr • $timeStr',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (tx.isInvoice)
                InkWell(
                  onTap: () => _viewInvoiceFromStatement(context, tx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 13,
                          color: Color(0xFF2196F3),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'View Bill',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: 0.7,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
          const SizedBox(height: 10),

          // Row 2: The 4 Core Bank Statement Figures
          Row(
            children: [
              // 1. Old Balance (Ketli balance hati)
              Expanded(
                child: _buildStatementColumn(
                  title: 'Old Balance',
                  value: _formatCurrency(tx.balanceBefore),
                  subValue: tx.balanceBefore > 0.001
                      ? 'Due'
                      : (tx.balanceBefore < -0.001 ? 'Adv' : 'Clear'),
                  valueColor: tx.balanceBefore > 0.001
                      ? const Color(0xFFFF5252)
                      : (tx.balanceBefore < -0.001
                          ? const Color(0xFF4CAF50)
                          : (isDark ? Colors.grey.shade300 : Colors.black87)),
                  subColor: tx.balanceBefore > 0.001
                      ? const Color(0xFFFF5252)
                      : (tx.balanceBefore < -0.001
                          ? const Color(0xFF4CAF50)
                          : Colors.grey),
                  isDark: isDark,
                ),
              ),

              Container(
                width: 1,
                height: 34,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),

              // 2. Bill Total (Ketlanu bill tyu)
              Expanded(
                child: _buildStatementColumn(
                  title: 'Bill Total',
                  value: tx.billAmount > 0
                      ? '+${_formatCurrency(tx.billAmount)}'
                      : '-',
                  subValue: tx.billAmount > 0 ? 'Debit' : '',
                  valueColor: tx.billAmount > 0
                      ? const Color(0xFFFF5252)
                      : Colors.grey,
                  subColor: const Color(0xFFFF5252),
                  isDark: isDark,
                ),
              ),

              Container(
                width: 1,
                height: 34,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),

              // 3. Paid / Got (Ketla paisa aavya)
              Expanded(
                child: _buildStatementColumn(
                  title: 'Paid / Got',
                  value: tx.paidAmount > 0
                      ? '-${_formatCurrency(tx.paidAmount)}'
                      : '-',
                  subValue: tx.paidAmount > 0 ? 'Credit' : '',
                  valueColor: tx.paidAmount > 0
                      ? const Color(0xFF4CAF50)
                      : Colors.grey,
                  subColor: const Color(0xFF4CAF50),
                  isDark: isDark,
                ),
              ),

              Container(
                width: 1,
                height: 34,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),

              // 4. Net Balance (ketla baki)
              Expanded(
                child: _buildStatementColumn(
                  title: 'Net Balance',
                  value: _formatCurrency(tx.balanceAfter),
                  subValue: balanceLabel,
                  valueColor: balanceColor,
                  subColor: balanceColor,
                  isBold: true,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatementColumn({
    required String title,
    required String value,
    required String subValue,
    required Color valueColor,
    required Color subColor,
    bool isBold = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
          if (subValue.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: subColor,
              ),
            ),
          ],
        ],
      ),
    );
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
