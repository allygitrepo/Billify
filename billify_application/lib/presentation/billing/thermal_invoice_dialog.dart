import 'package:billify/core/services/pdf_service.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/image_utils.dart';
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
import 'package:billify/providers/feature_settings_provider.dart';
import 'package:intl/intl.dart';

typedef InvoicePreviewDialog = ThermalInvoiceDialog;

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
  bool _isPrinting = false;
  String _selectedFormat = 'thermal'; // 'thermal' or 'a4'
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
      _remaining = totalDue - currentPaid;
    }
  }

  InvoiceModel get _effectiveInvoice {
    final currentBiz = ref.read(businessProvider).currentBusiness;

    if (_savedInvoice != null) {
      final inv = _savedInvoice!;
      var biz = inv.business;
      if (biz.phone.trim().isEmpty) {
        final fallbackPhone = currentBiz?.phone.trim().isNotEmpty == true
            ? currentBiz!.phone.trim()
            : widget.business.phone.trim();
        if (fallbackPhone.isNotEmpty) {
          biz = biz.copyWith(phone: fallbackPhone);
        }
      }
      if (biz.business_logo == null || biz.business_logo!.trim().isEmpty) {
        final fallbackLogo = currentBiz?.business_logo?.trim().isNotEmpty == true
            ? currentBiz!.business_logo
            : widget.business.business_logo;
        if (fallbackLogo != null && fallbackLogo.trim().isNotEmpty) {
          biz = biz.copyWith(business_logo: fallbackLogo);
        }
      }
      return inv.copyWith(business: biz);
    }
    if (widget.invoice != null) {
      final inv = widget.invoice!;
      var biz = inv.business;
      if (biz.phone.trim().isEmpty) {
        final fallbackPhone = currentBiz?.phone.trim().isNotEmpty == true
            ? currentBiz!.phone.trim()
            : widget.business.phone.trim();
        if (fallbackPhone.isNotEmpty) {
          biz = biz.copyWith(phone: fallbackPhone);
        }
      }
      if (biz.business_logo == null || biz.business_logo!.trim().isEmpty) {
        final fallbackLogo = currentBiz?.business_logo?.trim().isNotEmpty == true
            ? currentBiz!.business_logo
            : widget.business.business_logo;
        if (fallbackLogo != null && fallbackLogo.trim().isNotEmpty) {
          biz = biz.copyWith(business_logo: fallbackLogo);
        }
      }
      return inv.copyWith(business: biz);
    }

    var currentBusiness = currentBiz ?? widget.business;
    if (currentBusiness.phone.trim().isEmpty && widget.business.phone.trim().isNotEmpty) {
      currentBusiness = currentBusiness.copyWith(phone: widget.business.phone.trim());
    }
    if ((currentBusiness.business_logo == null || currentBusiness.business_logo!.trim().isEmpty) &&
        widget.business.business_logo != null &&
        widget.business.business_logo!.trim().isNotEmpty) {
      currentBusiness = currentBusiness.copyWith(business_logo: widget.business.business_logo!.trim());
    }

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
    final settings = ref.read(featureSettingsProvider);
    _selectedFormat = settings.invoicePrintFormat;
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
    _remaining = totalDue - initialPaid;
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  void _updateRemaining(String val) {
    final paid = double.tryParse(val) ?? 0.0;
    setState(() {
      _remaining = _effectiveTotalDue - paid;
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
    final String? currentName = widget.customer?.name ?? billing.customerName;
    final String? currentPhone =
        widget.customer?.phoneNumber ?? billing.customerPhone;
    final String? currentCity = widget.customer?.city ?? billing.customerCity;

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
        _paidController.text = _effectiveTotal.toStringAsFixed(2);
        _remaining = _effectivePreviousBalance;
      } else if (mode == 'KHATA') {
        _paidController.text = '0.00';
        _remaining = _effectiveTotalDue;
      } else if (mode == 'SPLIT') {
        final currentPaid = double.tryParse(_paidController.text) ?? 0.0;
        if (currentPaid <= 0 || currentPaid >= _effectiveTotalDue) {
          final half = (_effectiveTotalDue / 2);
          _paidController.text = half.toStringAsFixed(2);
          _remaining = _effectiveTotalDue - half;
        } else {
          _remaining = _effectiveTotalDue - currentPaid;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final currentBiz = businessState.currentBusiness;
    var business =
        widget.invoice?.business ?? currentBiz ?? widget.business;

    // Fallback if the business object on the invoice has empty phone
    if (business.phone.trim().isEmpty) {
      final fallbackPhone = currentBiz?.phone.trim().isNotEmpty == true
          ? currentBiz!.phone.trim()
          : widget.business.phone.trim();
      if (fallbackPhone.isNotEmpty) {
        business = business.copyWith(phone: fallbackPhone);
      }
    }
    if (business.address == null || business.address!.trim().isEmpty) {
      final fallbackAddr = currentBiz?.address?.trim().isNotEmpty == true
          ? currentBiz!.address
          : widget.business.address;
      if (fallbackAddr != null && fallbackAddr.trim().isNotEmpty) {
        business = business.copyWith(address: fallbackAddr);
      }
    }
    if (business.business_logo == null || business.business_logo!.trim().isEmpty) {
      final fallbackLogo = currentBiz?.business_logo?.trim().isNotEmpty == true
          ? currentBiz!.business_logo
          : widget.business.business_logo;
      if (fallbackLogo != null && fallbackLogo.trim().isNotEmpty) {
        business = business.copyWith(business_logo: fallbackLogo);
      }
    }

    final now = (_savedInvoice?.date ??
            widget.invoice?.date ??
            widget.invoiceDate ??
            DateTime.now())
        .toLocal();
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _selectedFormat == 'a4' ? 520 : 380,
          minWidth: 280,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Invoice Format Switcher (Thermal vs A4) ──
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedFormat = 'thermal'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: _selectedFormat == 'thermal'
                                  ? AppTheme.primaryTeal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 15,
                                  color: _selectedFormat == 'thermal'
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Thermal (80mm)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedFormat == 'thermal'
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedFormat = 'a4'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: _selectedFormat == 'a4'
                                  ? AppTheme.primaryTeal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 15,
                                  color: _selectedFormat == 'a4'
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Standard A4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedFormat == 'a4'
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFormat == 'a4')
                  _buildA4Preview(business, now, dateFormat, timeFormat)
                else
                  _buildThermalPreview(business, now, dateFormat, timeFormat),


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
              const _DashedDivider(),

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
                  )
                else if (_remaining < -0.01)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'JAMA TO KHATA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          '₹${(-_remaining).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
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
                        '₹${_effectiveTotalDue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ] else if (_paymentMode == 'SPLIT') ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _remaining < -0.001
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFFF9F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _remaining < -0.001
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'AMOUNT PAID (CASH)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 120,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _remaining < -0.001
                                      ? Colors.green.shade400
                                      : Colors.orange.shade400,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme:
                                      const InputDecorationTheme(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                                child: TextField(
                                  controller: _paidController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textAlign: TextAlign.right,
                                  autofocus: true,
                                  cursorColor: _remaining < -0.001
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      color: Colors.black38,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        left: 8,
                                        top: 9,
                                        bottom: 9,
                                        right: 2,
                                      ),
                                      child: Text(
                                        '₹',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                  ),
                                  onChanged: _updateRemaining,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: _remaining < -0.001
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _remaining < -0.001
                                        ? Colors.green
                                        : (_remaining > 0.001
                                            ? Colors.red
                                            : Colors.green),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _remaining < -0.001
                                      ? 'JAMA TO KHATA'
                                      : (_remaining > 0.001
                                          ? 'REMAINING TO KHATA'
                                          : 'BALANCE SETTLED'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _remaining < -0.001
                                        ? Colors.green.shade700
                                        : (_remaining > 0.001
                                            ? Colors.red
                                            : Colors.green.shade700),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${(_remaining < 0 ? -_remaining : _remaining).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _remaining < -0.001
                                    ? Colors.green.shade700
                                    : (_remaining > 0.001
                                        ? Colors.red
                                        : Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const _DashedDivider(),

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
                // Action Buttons for Confirmed / View-Only Mode
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting
                        ? null
                        : () async {
                            setState(() => _isPrinting = true);
                            try {
                              final inv = _effectiveInvoice;
                              await PdfService.printInvoice(
                                invoice: inv,
                                format: _selectedFormat,
                              );
                            } catch (e) {
                              if (mounted) {
                                AppFeedback.showError(
                                  context,
                                  'Error printing invoice: $e',
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isPrinting = false);
                              }
                            }
                          },
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.print_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isPrinting
                          ? 'OPENING PRINT DIALOG...'
                          : 'PRINT INVOICE (${_selectedFormat == 'a4' ? 'A4' : 'THERMAL'})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSharingInvoice
                        ? null
                        : () async {
                            setState(() => _isSharingInvoice = true);
                            try {
                              final inv = _effectiveInvoice;
                              final pdfFile =
                                  await PdfService.generateInvoicePdf(
                                invoice: inv,
                                format: _selectedFormat,
                              );
                              final fileName =
                                  PdfService.getInvoiceFileName(inv);
                              await Share.shareXFiles(
                                [
                                  XFile(
                                    pdfFile.path,
                                    name: fileName,
                                    mimeType: 'application/pdf',
                                  ),
                                ],
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
                                setState(() => _isSharingInvoice = false);
                              }
                            }
                          },
                    icon: _isSharingInvoice
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryTeal,
                            ),
                          )
                        : const Icon(
                            Icons.share_rounded,
                            size: 18,
                            color: AppTheme.primaryTeal,
                          ),
                    label: Text(
                      _isSharingInvoice
                          ? 'PREPARING PDF...'
                          : 'SHARE PDF (${_selectedFormat.toUpperCase()})',
                      style: const TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: AppTheme.primaryTeal,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('DONE / CLOSE'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: AppTheme.primaryTeal,
                            width: 1.5,
                          ),
                          foregroundColor: AppTheme.primaryTeal,
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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

                                final currentBiz =
                                    ref.read(businessProvider).currentBusiness;
                                var bizToUse = widget.business;
                                if (bizToUse.phone.trim().isEmpty &&
                                    currentBiz?.phone.trim().isNotEmpty == true) {
                                  bizToUse = bizToUse.copyWith(
                                    phone: currentBiz!.phone.trim(),
                                  );
                                }
                                if ((bizToUse.address == null ||
                                        bizToUse.address!.trim().isEmpty) &&
                                    currentBiz?.address?.trim().isNotEmpty ==
                                        true) {
                                  bizToUse = bizToUse.copyWith(
                                    address: currentBiz!.address,
                                  );
                                }
                                if ((bizToUse.business_logo == null ||
                                        bizToUse.business_logo!.trim().isEmpty) &&
                                    currentBiz?.business_logo?.trim().isNotEmpty ==
                                        true) {
                                  bizToUse = bizToUse.copyWith(
                                    business_logo: currentBiz!.business_logo,
                                  );
                                }

                                final invoice = await ref
                                    .read(billingProvider.notifier)
                                    .confirmInvoice(
                                      bizToUse,
                                      customTaxAmount: _effectiveTaxAmount,
                                      customGstAmount: _effectiveGstAmount,
                                      customFinalAmount: _effectiveTotal,
                                      customPreviousBalance:
                                          _effectivePreviousBalance,
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
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
    ),
  );
}

  Widget _buildThermalPreview(
    BusinessModel business,
    DateTime now,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    return Column(
      children: [
        if (business.business_logo != null &&
            business.business_logo!.trim().isNotEmpty) ...[
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: MemoryImage(
                  ImageUtils.decodeBase64(business.business_logo!),
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
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
        if (business.address != null && business.address!.trim().isNotEmpty)
          Text(
            business.address!,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        if (business.phone.trim().isNotEmpty)
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
                const _DashedDivider(),
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
        const _DashedDivider(),

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

        const _DashedDivider(),

        // Items Table Header
        const Row(
          children: [
            Expanded(
              flex: 7,
              child: Text(
                'ITEM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              flex: 3,
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
            SizedBox(width: 4),
            Expanded(
              flex: 5,
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
            SizedBox(width: 4),
            Expanded(
              flex: 6,
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
        const _DashedDivider(),

        // Items List
        ...widget.items.map(
          (item) {
            final qtyStr = item.product.is_weighted
                ? item.quantity.toStringAsFixed(2)
                : (item.quantity % 1 == 0
                    ? item.quantity.toInt().toString()
                    : item.quantity.toString());
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: Text(
                      qtyStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.price.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 6,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.subtotal.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const _DashedDivider(),

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
        const _DashedDivider(),
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
      ],
    );
  }

  Widget _buildA4Preview(
    BusinessModel business,
    DateTime now,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    final customers = ref.watch(customerProvider).value ?? [];
    final custId = widget.customerId ?? widget.invoice?.customer_id;
    final customer = widget.customer ??
        customers.where((c) => c.id == custId).firstOrNull;

    final customerName = customer?.name ??
        widget.invoice?.customer_name ??
        ref.watch(billingProvider).customerName ??
        (widget.customerId != null ? 'Regular Customer' : 'Walk-in Customer');
    final customerPhone = customer?.phoneNumber ??
        widget.invoice?.customer_phone ??
        ref.watch(billingProvider).customerPhone;
    final customerCity = customer?.city ??
        ref.watch(billingProvider).customerCity;

    final currentPaid = double.tryParse(_paidController.text) ?? _effectiveTotal;
    final isFullyPaid = (_effectiveTotalDue - currentPaid).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
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
          // ── Business Header & Invoice Badge ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (business.business_logo != null &&
                        business.business_logo!.trim().isNotEmpty)
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(
                            image: MemoryImage(
                              ImageUtils.decodeBase64(business.business_logo!),
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (business.address != null &&
                              business.address!.trim().isNotEmpty)
                            Text(
                              business.address!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.black87,
                              ),
                            ),
                          if (business.phone.trim().isNotEmpty)
                            Text(
                              'Phone: ${business.phone}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.black87,
                              ),
                            ),
                          if (business.gstin != null &&
                              business.gstin!.trim().isNotEmpty)
                            Text(
                              'GSTIN: ${business.gstin}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TAX INVOICE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INV #: ${widget.invoiceId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${dateFormat.format(now)} ${timeFormat.format(now)}',
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Mode: ${_paymentMode.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: AppTheme.primaryTeal),
          const SizedBox(height: 8),

          // ── Customer Details Box ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BILLED TO:',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        customerName,
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
                            fontSize: 9.5,
                            color: Colors.black87,
                          ),
                        ),
                      if (customerCity != null && customerCity.isNotEmpty)
                        Text(
                          'City: $customerCity',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isFullyPaid
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isFullyPaid ? Colors.green : Colors.amber.shade700,
                    ),
                  ),
                  child: Text(
                    isFullyPaid ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: isFullyPaid
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Items Table ──────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: AppTheme.primaryTeal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'ITEM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'QTY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'RATE',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'TOTAL',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...List.generate(widget.items.length, (idx) {
                  final e = widget.items[idx];
                  final item = e is CartItemModel
                      ? e
                      : CartItemModel.fromJson(e as Map<String, dynamic>);
                  final qtyStr = item.product.is_weighted
                      ? item.quantity.toStringAsFixed(3)
                      : (item.quantity % 1 == 0
                          ? item.quantity.toInt().toString()
                          : item.quantity.toString());

                  return Container(
                    color: idx % 2 == 1 ? Colors.grey.shade50 : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$qtyStr ${item.product.uom}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.subtotal.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Totals Grid ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _A4SummaryRow(
                  label: 'Subtotal',
                  value: '₹${_subtotal.toStringAsFixed(2)}',
                ),
                if (_effectiveTaxAmount > 0)
                  _A4SummaryRow(
                    label: _taxPercent > 0 ? 'Tax ($_taxPercent%)' : 'Tax',
                    value: '₹${_effectiveTaxAmount.toStringAsFixed(2)}',
                  ),
                if (_effectiveGstAmount > 0)
                  _A4SummaryRow(
                    label: _gstPercent > 0 ? 'GST ($_gstPercent%)' : 'GST',
                    value: '₹${_effectiveGstAmount.toStringAsFixed(2)}',
                  ),
                if (_effectivePreviousBalance > 0) ...[
                  _A4SummaryRow(
                    label: 'Previous Balance',
                    value: '₹${_effectivePreviousBalance.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  _A4SummaryRow(
                    label: 'Total Due',
                    value: '₹${_effectiveTotalDue.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
                const Divider(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _effectivePreviousBalance > 0
                            ? 'BILL TOTAL'
                            : 'GRAND TOTAL',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      Text(
                        '₹${_effectiveTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _A4SummaryRow(
                  label: 'Paid Amount',
                  value: '₹${currentPaid.toStringAsFixed(2)}',
                ),
                if (_remaining > 0.01)
                  _A4SummaryRow(
                    label: 'Balance to Khata',
                    value: '₹${_remaining.toStringAsFixed(2)}',
                    valueColor: Colors.red.shade700,
                    isBold: true,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Thank you for your business!',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _A4SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _A4SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              displayVal,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
                color: Colors.black,
              ),
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
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: AppTheme.primaryTeal,
                          width: 1.5,
                        ),
                        foregroundColor: AppTheme.primaryTeal,
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'CONTINUE TO KHATA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 4.0;
          const dashSpace = 3.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          if (dashCount <= 0) return const SizedBox.shrink();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black26),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
