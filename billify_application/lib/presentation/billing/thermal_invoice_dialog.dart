import 'package:billify/core/services/pdf_service.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/data/models/business_model.dart';
import 'package:billify/data/models/cart_item_model.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/providers/billing_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:billify/data/models/invoice_model.dart';
import 'package:intl/intl.dart';

class ThermalInvoiceDialog extends ConsumerStatefulWidget {
  final List<dynamic> items;
  final BusinessModel business;
  final double subtotal;
  final double taxAmount;
  final double gstAmount;
  final double total;
  final String invoiceId;
  final int? customerId;
  final String? customerType;
  final Customer? customer;

  const ThermalInvoiceDialog({
    super.key,
    required this.items,
    required this.business,
    required this.subtotal,
    required this.taxAmount,
    required this.gstAmount,
    required this.total,
    required this.invoiceId,
    this.customerId,
    this.customerType = 'WALKIN',
    this.customer,
    this.isViewOnly = false,
    this.invoiceDate,
    this.initialPaidAmount,
    this.initialPaymentMode,
    this.invoice,
    this.previousBalance,
  });

  final bool isViewOnly;
  final DateTime? invoiceDate;
  final double? initialPaidAmount;
  final String? initialPaymentMode;
  final InvoiceModel? invoice;
  final double? previousBalance;

  @override
  ConsumerState<ThermalInvoiceDialog> createState() =>
      _ThermalInvoiceDialogState();
}

class _ThermalInvoiceDialogState extends ConsumerState<ThermalInvoiceDialog> {
  late TextEditingController _paidController;
  late double _remaining;
  String _paymentMode = 'CASH'; // 'CASH', 'KHATA', 'SPLIT'
  bool _isConfirmed = false;
  InvoiceModel? _savedInvoice;
  bool _isSaving = false;
  bool _isSharingInvoice = false;
  late bool _applyTax;
  late bool _applyGst;

  double get _subtotal => widget.invoice?.total_amount ?? widget.subtotal;

  double get _taxPercent {
    if (widget.invoice != null) {
      return widget.invoice!.business.tax_percentage;
    }
    return _applyTax ? widget.business.tax_percentage : 0.0;
  }

  double get _gstPercent {
    if (widget.invoice != null) {
      return widget.invoice!.business.gst_percentage;
    }
    return _applyGst ? widget.business.gst_percentage : 0.0;
  }

  double get _effectiveTaxAmount {
    if (widget.invoice != null) return widget.invoice!.tax_amount;
    if (!_applyTax) return 0.0;
    return _subtotal * (_taxPercent / 100);
  }

  double get _effectiveGstAmount {
    if (widget.invoice != null) return widget.invoice!.gst_amount;
    if (!_applyGst) return 0.0;
    return _subtotal * (_gstPercent / 100);
  }

  double get _effectiveTotal {
    if (widget.invoice != null) return widget.invoice!.final_amount;
    return _subtotal + _effectiveTaxAmount + _effectiveGstAmount;
  }

  void _toggleTax(bool value) {
    setState(() {
      _applyTax = value;
      _recalcPaidAndRemaining();
    });
  }

  void _toggleGst(bool value) {
    setState(() {
      _applyGst = value;
      _recalcPaidAndRemaining();
    });
  }

  double get _effectivePreviousBalance {
    if (widget.invoice != null) return widget.invoice!.previous_balance;
    return widget.previousBalance ?? widget.customer?.remainingBalance ?? 0.0;
  }

  double get _effectiveTotalDue => _effectiveTotal + _effectivePreviousBalance;

  void _recalcPaidAndRemaining() {
    final total = _effectiveTotal;
    final totalDue = _effectiveTotalDue;
    if (_paymentMode == 'CASH') {
      _paidController.text = total.toStringAsFixed(2);
      _remaining = _effectivePreviousBalance;
    } else if (_paymentMode == 'KHATA') {
      _paidController.text = '0.00';
      _remaining = totalDue;
    } else if (_paymentMode == 'SPLIT') {
      final currentPaid = double.tryParse(_paidController.text) ?? (total / 2);
      _remaining = (totalDue - currentPaid).clamp(0.0, double.infinity);
    }
  }

  InvoiceModel get _effectiveInvoice {
    if (_savedInvoice != null) return _savedInvoice!;
    if (widget.invoice != null) return widget.invoice!;

    final currentBusiness =
        ref.read(businessProvider).currentBusiness ?? widget.business;

    final paid =
        double.tryParse(_paidController.text) ??
        (widget.initialPaidAmount ?? _effectiveTotal);

    final resolvedCustomerName =
        widget.customer?.name ??
        ref.read(billingProvider).customerName ??
        (widget.customerId != null ? 'Regular Customer' : null);
    final resolvedCustomerPhone =
        widget.customer?.phoneNumber ??
        ref.read(billingProvider).customerPhone;

    return InvoiceModel(
      id: widget.invoiceId,
      date: (_savedInvoice?.date ?? widget.invoiceDate ?? DateTime.now())
          .toLocal(),
      business: currentBusiness,
      items: widget.items.map((e) {
        if (e is CartItemModel) return e;
        return CartItemModel.fromJson(e as Map<String, dynamic>);
      }).toList(),
      total_amount: _subtotal,
      tax_amount: _effectiveTaxAmount,
      gst_amount: _effectiveGstAmount,
      final_amount: _effectiveTotal,
      staff_name: 'Owner',
      customer_id: widget.customerId,
      customer_type: widget.customerType,
      customer_name: resolvedCustomerName,
      customer_phone: resolvedCustomerPhone,
      paid_amount: paid,
      payment_mode: _paymentMode,
      previous_balance: _effectivePreviousBalance,
    );
  }

  @override
  void initState() {
    super.initState();
    final rawMode =
        widget.invoice?.payment_mode ?? widget.initialPaymentMode ?? 'CASH';
    _paymentMode = rawMode.toUpperCase();

    if (widget.invoice != null) {
      _applyTax = widget.invoice!.tax_amount > 0;
      _applyGst = widget.invoice!.gst_amount > 0;
    } else {
      _applyTax = widget.business.tax_percentage > 0;
      _applyGst = widget.business.gst_percentage > 0;
    }

    final initialPaid =
        widget.invoice?.paid_amount ?? widget.initialPaidAmount ?? _effectiveTotal;
    _paidController = TextEditingController(
      text: initialPaid.toStringAsFixed(2),
    );
    final totalDue = widget.invoice != null
        ? (widget.invoice!.final_amount + widget.invoice!.previous_balance)
        : _effectiveTotalDue;
    _remaining = (totalDue - initialPaid).clamp(0.0, double.infinity);
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  void _updateRemaining(String val) {
    final paid = double.tryParse(val) ?? 0.0;
    setState(() {
      _remaining = (_effectiveTotalDue - paid).clamp(0.0, double.infinity);
    });
  }

  Future<bool> _ensureCustomerForCredit() async {
    final billing = ref.read(billingProvider);

    // 1. Check if already has a registered customer ID
    final custId = widget.customerId ??
        widget.invoice?.customer_id ??
        billing.selectedCustomerId;
    if (custId != null) return true;

    // 2. Check if name and phone are already available in state or widget
    String? currentName = widget.customer?.name ?? billing.customerName;
    String? currentPhone =
        widget.customer?.phoneNumber ?? billing.customerPhone;
    String? currentCity = widget.customer?.city ?? billing.customerCity;

    if (currentName != null &&
        currentName.trim().isNotEmpty &&
        currentName != 'Walk-in Customer' &&
        currentPhone != null &&
        currentPhone.trim().isNotEmpty) {
      try {
        final businessId =
            ref.read(businessProvider).currentBusinessId ?? 'default';
        final newCustomer = Customer(
          businessId: businessId,
          name: currentName.trim(),
          phoneNumber: currentPhone.trim(),
          city: currentCity?.trim().isNotEmpty == true
              ? currentCity!.trim()
              : null,
        );
        final saved = await ref
            .read(customerProvider.notifier)
            .saveCustomer(newCustomer);
        ref.read(billingProvider.notifier).setCustomer(
              saved.id,
              'REGULAR',
              name: saved.name,
              phone: saved.phoneNumber,
              city: saved.city,
            );
        return true;
      } catch (_) {
        // Fallback to manual dialog below
      }
    }

    // 3. Prompt user for mandatory Name & Phone
    if (!mounted) return false;
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _KhataCustomerRequiredDialog(
        initialName:
            currentName != 'Walk-in Customer' ? (currentName ?? '') : '',
        initialPhone: currentPhone ?? '',
        initialCity: currentCity ?? '',
      ),
    );

    if (result == null) return false;

    final name = result['name']!;
    final phone = result['phone']!;
    final city = result['city'];

    try {
      final businessId =
          ref.read(businessProvider).currentBusinessId ?? 'default';
      final newCustomer = Customer(
        businessId: businessId,
        name: name,
        phoneNumber: phone,
        city: city?.isNotEmpty == true ? city : null,
      );
      final saved =
          await ref.read(customerProvider.notifier).saveCustomer(newCustomer);

      ref.read(billingProvider.notifier).setCustomer(
            saved.id,
            'REGULAR',
            name: saved.name,
            phone: saved.phoneNumber,
            city: saved.city,
          );
      return true;
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Failed to save customer for Khata: $e');
      }
      return false;
    }
  }

  Future<void> _setMode(String mode) async {
    if (mode == 'KHATA' || mode == 'SPLIT') {
      final hasCustomer = await _ensureCustomerForCredit();
      if (!hasCustomer) {
        if (mounted) {
          AppFeedback.showWarning(
            context,
            'Customer Name & Phone are mandatory for Khata (Credit)',
          );
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _paymentMode = mode;
      if (mode == 'CASH') {
        _paidController.text = widget.total.toStringAsFixed(2);
        _remaining = 0.0;
      } else if (mode == 'KHATA') {
        _paidController.text = '0.00';
        _remaining = widget.total;
      } else if (mode == 'SPLIT') {
        final currentPaid = double.tryParse(_paidController.text) ?? 0.0;
        if (currentPaid <= 0 || currentPaid >= widget.total) {
          final half = (widget.total / 2);
          _paidController.text = half.toStringAsFixed(2);
          _remaining = widget.total - half;
        } else {
          _remaining = (widget.total - currentPaid).clamp(0.0, double.infinity);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final business =
        widget.invoice?.business ?? businessState.currentBusiness ?? widget.business;

    final now = (_savedInvoice?.date ??
            widget.invoice?.date ??
            widget.invoiceDate ??
            DateTime.now())
        .toLocal();
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isRegular = widget.customerType == 'REGULAR';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Container(
          width: 320, // Typical thermal width
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                business.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              if (business.address != null)
                Text(
                  business.address!,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              Text(
                'Phone: ${business.phone}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              if (business.gstin != null && business.gstin!.isNotEmpty)
                Text(
                  'GSTIN: ${business.gstin}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 8),
              Text(
                'INVOICE NO: ${widget.invoiceId}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              Consumer(
                builder: (context, ref, _) {
                  final customers = ref.watch(customerProvider).value ?? [];
                  final custId =
                      widget.customerId ?? widget.invoice?.customer_id;
                  final customer =
                      widget.customer ??
                      customers.where((c) => c.id == custId).firstOrNull;

                  final customerName =
                      customer?.name ??
                      widget.invoice?.customer_name ??
                      ref.watch(billingProvider).customerName;
                  final customerPhone =
                      customer?.phoneNumber ??
                      widget.invoice?.customer_phone ??
                      ref.watch(billingProvider).customerPhone;

                  final customerCity =
                      customer?.city ??
                      ref.watch(billingProvider).customerCity;

                  final hasCustomer =
                      (customerName != null &&
                          customerName.isNotEmpty &&
                          customerName != 'Walk-in Customer') ||
                      (customerPhone != null && customerPhone.isNotEmpty) ||
                      (customerCity != null && customerCity.isNotEmpty) ||
                      (widget.customerType == 'REGULAR' && widget.customerId != null);

                  if (!hasCustomer) return const SizedBox.shrink();

                  return Column(
                    children: [
                      const Text(
                        '-----------------------------------------',
                        style: TextStyle(color: Colors.black38),
                      ),
                      if (customerName != null && customerName.isNotEmpty)
                        Text(
                          'CUSTOMER: ${customerName.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      if (customerPhone != null && customerPhone.isNotEmpty)
                        Text(
                          'Phone: $customerPhone',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                      if (customerCity != null && customerCity.isNotEmpty)
                        Text(
                          'City: $customerCity',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),

              // Date & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${dateFormat.format(now)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                  Text(
                    'Time: ${timeFormat.format(now)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),

              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),

              // Items Table Header
              const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'ITEM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'QTY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PRICE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TOTAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),

              // Items List
              ...widget.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.price.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.subtotal.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),

              // Totals
              _PriceRow(label: 'SUBTOTAL', value: _subtotal),
              if (_effectiveTaxAmount > 0)
                _PriceRow(
                  label: _taxPercent > 0 ? 'TAX ($_taxPercent%)' : 'TAX',
                  value: _effectiveTaxAmount,
                ),
              if (_effectiveGstAmount > 0)
                _PriceRow(
                  label: _gstPercent > 0 ? 'GST ($_gstPercent%)' : 'GST',
                  value: _effectiveGstAmount,
                ),
              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),
              _PriceRow(
                label: _effectivePreviousBalance > 0 ? 'BILL TOTAL' : 'GRAND TOTAL',
                value: _effectiveTotal,
                isBold: true,
                fontSize: 14,
              ),
              if (_effectivePreviousBalance > 0) ...[
                const SizedBox(height: 2),
                _PriceRow(
                  label: 'PREVIOUS BALANCE',
                  value: _effectivePreviousBalance,
                  isBold: true,
                  fontSize: 12,
                ),
                const SizedBox(height: 2),
                _PriceRow(
                  label: 'TOTAL DUE',
                  value: _effectiveTotalDue,
                  isBold: true,
                  fontSize: 14,
                ),
              ],

              // Tax & GST Toggle Switches for New Invoices
              if (!widget.isViewOnly && widget.invoice == null && !_isConfirmed)
                if (widget.business.tax_percentage > 0 ||
                    widget.business.gst_percentage > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TAX & GST SETTINGS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.business.tax_percentage > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _applyTax,
                                      activeColor: AppTheme.primaryTeal,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (v) => _toggleTax(v ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Include Tax (${widget.business.tax_percentage}%)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${(_subtotal * (widget.business.tax_percentage / 100)).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _applyTax
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontWeight: _applyTax
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        if (widget.business.gst_percentage > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _applyGst,
                                      activeColor: AppTheme.primaryTeal,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (v) => _toggleGst(v ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Include GST (${widget.business.gst_percentage}%)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${(_subtotal * (widget.business.gst_percentage / 100)).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _applyGst
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontWeight: _applyGst
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),

              // Payment Section
              if (_isConfirmed || widget.isViewOnly) ...[
                _PriceRow(
                  label: 'PAYMENT MODE',
                  valueString: _paymentMode.toUpperCase(),
                  isBold: true,
                ),
                _PriceRow(
                  label: 'AMOUNT PAID',
                  value:
                      widget.invoice?.paid_amount ??
                      double.tryParse(_paidController.text) ??
                      widget.total,
                  isBold: true,
                ),
                if (_remaining > 0.01)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'REMAINING TO KHATA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '₹${_remaining.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                // Payment Mode Selection
                Column(
                  children: [
                    const Text(
                      'CHOOSE PAYMENT MODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            label: 'CASH',
                            isSelected: _paymentMode == 'CASH',
                            color: Colors.green,
                            onTap: () => _setMode('CASH'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ModeButton(
                            label: 'KHATA',
                            isSelected: _paymentMode == 'KHATA',
                            color: Colors.red,
                            onTap: () => _setMode('KHATA'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ModeButton(
                            label: 'SPLIT',
                            isSelected: _paymentMode == 'SPLIT',
                            color: Colors.orange,
                            onTap: () => _setMode('SPLIT'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Interactive Summary based on mode
                if (_paymentMode == 'CASH')
                  const Center(
                    child: Text(
                      'FULL PAYMENT RECEIVED (CASH)',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (_paymentMode == 'KHATA') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL BAL. TO KHATA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '₹${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ] else if (_paymentMode == 'SPLIT') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AMOUNT PAID (CASH)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 25,
                        child: TextField(
                          controller: _paidController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: UnderlineInputBorder(),
                            hintText: '0.00',
                            prefixText: '₹',
                          ),
                          onChanged: _updateRemaining,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'REMAINING TO KHATA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '₹${_remaining.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),

              const SizedBox(height: 12),
              const Text(
                'THANK YOU FOR YOUR BUSINESS!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (_isConfirmed || widget.isViewOnly) ...[
                if (_isConfirmed) ...[
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'INVOICE SAVED SUCCESSFULLY!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.customerType == 'REGULAR' ||
                    widget.customerId != null ||
                    widget.customer != null ||
                    widget.invoice?.customer_id != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final customers = ref.watch(customerProvider).value ?? [];
                      final custId =
                          widget.customerId ?? widget.invoice?.customer_id;
                      final customer =
                          widget.customer ??
                          customers.where((c) => c.id == custId).firstOrNull;

                      final phone =
                          customer?.phoneNumber ??
                          widget.invoice?.customer_phone ??
                          ref.watch(billingProvider).customerPhone;

                      if (phone == null || phone.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSharingInvoice
                                  ? null
                                  : () async {
                                      setState(() => _isSharingInvoice = true);
                                      try {
                                        final inv = _effectiveInvoice;
                                        final pdfFile =
                                            await PdfService.generateInvoicePdf(
                                              invoice: inv,
                                            );
                                        await Share.shareXFiles(
                                          [XFile(pdfFile.path)],
                                          text:
                                              'Invoice No: ${inv.id}\nAmount: ₹${inv.final_amount.toStringAsFixed(2)}\nThank you for shopping with us!',
                                        );
                                      } catch (e) {
                                        if (mounted) {
                                          AppFeedback.showError(
                                            context,
                                            'Error sharing PDF: $e',
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(
                                            () => _isSharingInvoice = false,
                                          );
                                        }
                                      }
                                    },
                              icon: _isSharingInvoice
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.share,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isSharingInvoice
                                    ? 'PREPARING PDF...'
                                    : 'SHARE INVOICE (PDF)',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('DONE / CLOSE'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ] else if (!widget.isViewOnly)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (_paymentMode == 'KHATA' ||
                                    _paymentMode == 'SPLIT') {
                                  final hasCustomer =
                                      await _ensureCustomerForCredit();
                                  if (!hasCustomer) {
                                    if (mounted) {
                                      AppFeedback.showWarning(
                                        context,
                                        'Customer details are required for Khata / Split payment',
                                      );
                                    }
                                    return;
                                  }
                                }
                                setState(() => _isSaving = true);
                                final paid =
                                    double.tryParse(_paidController.text) ??
                                    0.0;
                                ref
                                    .read(billingProvider.notifier)
                                    .setPaymentDetails(
                                      paidAmount: paid,
                                      paymentMode: _paymentMode,
                                    );

                                final invoice = await ref
                                    .read(billingProvider.notifier)
                                    .confirmInvoice(
                                      widget.business,
                                      customTaxAmount: _effectiveTaxAmount,
                                      customGstAmount: _effectiveGstAmount,
                                      customFinalAmount: _effectiveTotal,
                                    );

                                if (mounted) {
                                  if (invoice != null) {
                                    setState(() {
                                      _isConfirmed = true;
                                      _savedInvoice = invoice;
                                      _isSaving = false;
                                    });
                                    AppFeedback.showSuccess(
                                      context,
                                      'Invoice saved successfully',
                                    );
                                  } else {
                                    setState(() => _isSaving = false);
                                    AppFeedback.showError(
                                      context,
                                      'Failed to save invoice',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _paymentMode == 'CASH'
                                    ? 'CONFIRM (PAID)'
                                    : _paymentMode == 'KHATA'
                                    ? 'CONFIRM (KHATA)'
                                    : 'CONFIRM (SPLIT)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                      ),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double? value;
  final String? valueString;
  final bool isBold;
  final double fontSize;

  const _PriceRow({
    required this.label,
    this.value,
    this.valueString,
    this.isBold = false,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final displayVal =
        valueString ?? (value != null ? '₹${value!.toStringAsFixed(2)}' : '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: Colors.black,
            ),
          ),
          Text(
            displayVal,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _KhataCustomerRequiredDialog extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialCity;

  const _KhataCustomerRequiredDialog({
    required this.initialName,
    required this.initialPhone,
    required this.initialCity,
  });

  @override
  State<_KhataCustomerRequiredDialog> createState() =>
      _KhataCustomerRequiredDialogState();
}

class _KhataCustomerRequiredDialogState
    extends State<_KhataCustomerRequiredDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'city': _cityController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppTheme.primaryTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khata Customer Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mandatory to record credit',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'e.g. Rahul Sharma',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) =>
                    Validators.validateRequired(val, 'Customer Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => Validators.validatePhone(val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'City / Area (Optional)',
                  hintText: 'e.g. Surat',
                  prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                      ),
                      child: const Text(
                        'CONTINUE TO KHATA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
  }
}
