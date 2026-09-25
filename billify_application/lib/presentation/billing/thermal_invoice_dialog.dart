import 'package:billify/core/services/pdf_service.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/business_model.dart';
import 'package:billify/data/models/cart_item_model.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/providers/billing_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:billify/presentation/customers/customer_detail_screen.dart';
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
  });

  final bool isViewOnly;
  final DateTime? invoiceDate;
  final double? initialPaidAmount;
  final String? initialPaymentMode;
  final InvoiceModel? invoice;

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

  InvoiceModel get _effectiveInvoice {
    if (_savedInvoice != null) return _savedInvoice!;

    final currentBusiness =
        ref.read(businessProvider).currentBusiness ?? widget.business;

    final taxPercent = currentBusiness.tax_percentage > 0
        ? currentBusiness.tax_percentage
        : widget.business.tax_percentage;
    final gstPercent = currentBusiness.gst_percentage > 0
        ? currentBusiness.gst_percentage
        : widget.business.gst_percentage;

    final effectiveTaxAmount = widget.taxAmount > 0
        ? widget.taxAmount
        : (widget.subtotal * (taxPercent / 100));
    final effectiveGstAmount = widget.gstAmount > 0
        ? widget.gstAmount
        : (widget.subtotal * (gstPercent / 100));
    final effectiveTotal = widget.total > widget.subtotal
        ? widget.total
        : (widget.subtotal + effectiveTaxAmount + effectiveGstAmount);

    if (widget.invoice != null) {
      return widget.invoice!.copyWith(
        business: currentBusiness,
        tax_amount: widget.invoice!.tax_amount > 0
            ? widget.invoice!.tax_amount
            : effectiveTaxAmount,
        gst_amount: widget.invoice!.gst_amount > 0
            ? widget.invoice!.gst_amount
            : effectiveGstAmount,
        final_amount: widget.invoice!.final_amount > 0
            ? widget.invoice!.final_amount
            : effectiveTotal,
      );
    }

    final paid =
        double.tryParse(_paidController.text) ??
        (widget.initialPaidAmount ?? effectiveTotal);

    final resolvedCustomerName =
        widget.customer?.name ??
        ref.read(billingProvider).customerName ??
        (widget.customerId != null ? 'Regular Customer' : 'Walk-in Customer');
    final resolvedCustomerPhone =
        widget.customer?.phoneNumber ??
        ref.read(billingProvider).customerPhone ??
        '';

    return InvoiceModel(
      id: widget.invoiceId,
      date: widget.invoiceDate ?? DateTime.now(),
      business: currentBusiness,
      items: widget.items.map((e) {
        if (e is CartItemModel) return e;
        return CartItemModel.fromJson(e as Map<String, dynamic>);
      }).toList(),
      total_amount: widget.subtotal,
      tax_amount: effectiveTaxAmount,
      gst_amount: effectiveGstAmount,
      final_amount: effectiveTotal,
      staff_name: 'Owner',
      customer_id: widget.customerId,
      customer_type: widget.customerType,
      customer_name: resolvedCustomerName,
      customer_phone: resolvedCustomerPhone,
      paid_amount: paid,
      payment_mode: _paymentMode,
    );
  }

  @override
  void initState() {
    super.initState();
    final rawMode =
        widget.invoice?.payment_mode ?? widget.initialPaymentMode ?? 'CASH';
    _paymentMode = rawMode.toUpperCase();

    final initialPaid =
        widget.invoice?.paid_amount ?? widget.initialPaidAmount ?? widget.total;
    _paidController = TextEditingController(
      text: initialPaid.toStringAsFixed(2),
    );
    final totalAmt = widget.invoice?.final_amount ?? widget.total;
    _remaining = (totalAmt - initialPaid).clamp(0.0, double.infinity);
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  void _updateRemaining(String val) {
    final paid = double.tryParse(val) ?? 0.0;
    setState(() {
      _remaining = (widget.total - paid).clamp(0.0, double.infinity);
    });
  }

  void _setMode(String mode) {
    if (mode == 'KHATA' && widget.customerType != 'REGULAR') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer first for Khata (Credit)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _paymentMode = mode;
      if (mode == 'CASH') {
        _paidController.text = widget.total.toStringAsFixed(2);
        _remaining = 0.0;
      } else if (mode == 'KHATA') {
        _paidController.text = '0.00';
        _remaining = widget.total;
      }
      // If SPLIT, keep current text but allow editing
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final business = businessState.currentBusiness ?? widget.business;

    final taxPercent = business.tax_percentage > 0
        ? business.tax_percentage
        : widget.business.tax_percentage;
    final gstPercent = business.gst_percentage > 0
        ? business.gst_percentage
        : widget.business.gst_percentage;

    final effectiveTaxAmount = widget.taxAmount > 0
        ? widget.taxAmount
        : (widget.subtotal * (taxPercent / 100));
    final effectiveGstAmount = widget.gstAmount > 0
        ? widget.gstAmount
        : (widget.subtotal * (gstPercent / 100));
    final effectiveTotal = widget.total > widget.subtotal
        ? widget.total
        : (widget.subtotal + effectiveTaxAmount + effectiveGstAmount);

    final now = widget.invoiceDate ?? DateTime.now();
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

                  final hasCustomer =
                      (customerName != null &&
                          customerName.isNotEmpty &&
                          customerName != 'Walk-in Customer') ||
                      (customerPhone != null && customerPhone.isNotEmpty) ||
                      widget.customerType == 'REGULAR';

                  if (!hasCustomer) return const SizedBox.shrink();

                  return Column(
                    children: [
                      const Text(
                        '-----------------------------------------',
                        style: TextStyle(color: Colors.black38),
                      ),
                      Text(
                        'CUSTOMER: ${(customerName ?? 'REGULAR CUSTOMER').toUpperCase()}',
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
              _PriceRow(label: 'SUBTOTAL', value: widget.subtotal),
              if (effectiveTaxAmount > 0 || taxPercent > 0)
                _PriceRow(
                  label: taxPercent > 0 ? 'TAX ($taxPercent%)' : 'TAX',
                  value: effectiveTaxAmount,
                ),
              if (effectiveGstAmount > 0 || gstPercent > 0)
                _PriceRow(
                  label: gstPercent > 0 ? 'GST ($gstPercent%)' : 'GST',
                  value: effectiveGstAmount,
                ),
              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),
              _PriceRow(
                label: 'GRAND TOTAL',
                value: effectiveTotal,
                isBold: true,
                fontSize: 14,
              ),
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
                        if (isRegular) ...[
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
                else if (_paymentMode == 'KHATA' && isRegular) ...[
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
                ] else if (_paymentMode == 'SPLIT' && isRegular) ...[
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
                ] else if (_paymentMode != 'CASH' && !isRegular)
                  const Center(
                    child: Text(
                      'REGULAR CUSTOMER NEEDED',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error sharing: $e',
                                              ),
                                            ),
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
                                    .confirmInvoice(widget.business);

                                if (mounted) {
                                  if (invoice != null) {
                                    setState(() {
                                      _isConfirmed = true;
                                      _savedInvoice = invoice;
                                      _isSaving = false;
                                    });
                                  } else {
                                    setState(() => _isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to save invoice'),
                                        backgroundColor: Colors.red,
                                      ),
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
