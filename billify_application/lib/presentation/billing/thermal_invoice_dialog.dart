import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/business_model.dart';
import 'package:billify_application/providers/billing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billify_application/providers/customer_provider.dart';
import 'package:billify_application/presentation/customers/customer_detail_screen.dart';
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
    this.isViewOnly = false,
  });

  final bool isViewOnly;

  @override
  ConsumerState<ThermalInvoiceDialog> createState() =>
      _ThermalInvoiceDialogState();
}

class _ThermalInvoiceDialogState extends ConsumerState<ThermalInvoiceDialog> {
  late TextEditingController _paidController;
  late double _remaining;
  String _paymentMode = 'CASH'; // 'CASH', 'KHATA', 'SPLIT'

  @override
  void initState() {
    super.initState();
    _paidController = TextEditingController(
      text: widget.total.toStringAsFixed(2),
    );
    _remaining = 0.0;
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  void _updateRemaining(String val) {
    final paid = double.tryParse(val) ?? 0.0;
    setState(() {
      _remaining = widget.total - paid;
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
      // If SPLIT, we keep the current text but allow editing
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
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
                widget.business.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.business.address != null)
                Text(
                  widget.business.address!,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              Text(
                'Phone: ${widget.business.phone}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              if (widget.business.gstin != null &&
                  widget.business.gstin!.isNotEmpty)
                Text(
                  'GSTIN: ${widget.business.gstin}',
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

              if (widget.customerType == 'REGULAR' && widget.customerId != null)
                Consumer(
                  builder: (context, ref, _) {
                    final customers = ref.watch(customerProvider).value ?? [];
                    final customer = customers
                        .where((c) => c.id == widget.customerId)
                        .firstOrNull;
                    return Column(
                      children: [
                        const Text(
                          '-----------------------------------------',
                          style: TextStyle(color: Colors.black38),
                        ),
                        Text(
                          'CUSTOMER: ${customer?.name.toUpperCase() ?? 'REGULAR'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (customer?.phoneNumber != null)
                          Text(
                            'Phone: ${customer?.phoneNumber}',
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
              if (widget.business.tax_percentage > 0)
                _PriceRow(
                  label: 'TAX (${widget.business.tax_percentage}%)',
                  value: widget.taxAmount,
                ),
              if (widget.business.gst_percentage > 0)
                _PriceRow(
                  label: 'GST (${widget.business.gst_percentage}%)',
                  value: widget.gstAmount,
                ),
              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),
              _PriceRow(
                label: 'GRAND TOTAL',
                value: widget.total,
                isBold: true,
                fontSize: 14,
              ),
              const Text(
                '-----------------------------------------',
                style: TextStyle(color: Colors.black38),
              ),

              // Payment Mode Selection
              if (!widget.isViewOnly) ...[
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
              ],

              const SizedBox(height: 16),

              // Summary of Payment based on mode
              if (_paymentMode == 'CASH')
                const Center(
                  child: Text(
                    'FULL PAYMENT RECEIVED',
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
              if (!widget.isViewOnly)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final paid =
                              double.tryParse(_paidController.text) ?? 0.0;
                          ref
                              .read(billingProvider.notifier)
                              .setPaidAmount(paid);

                          await ref
                              .read(billingProvider.notifier)
                              .confirmInvoice(widget.business);

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invoice confirmed and saved'),
                              ),
                            );

                            // Auto-navigate to Customer Details for Khata/Split
                            // if ((_paymentMode == 'KHATA' || _paymentMode == 'SPLIT') &&
                            //     widget.customerId != null) {
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) =>
                            //           CustomerDetailScreen(customerId: widget.customerId!),
                            //     ),
                            //   );
                            // }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                        ),
                        child: Text(
                          _paymentMode == 'CASH'
                              ? 'CONFIRM (PAID)'
                              : _paymentMode == 'KHATA'
                                  ? 'CONFIRM (KHATA)'
                                  : 'CONFIRM (SPLIT)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
  final double value;
  final bool isBold;
  final double fontSize;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
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
            '₹${value.toStringAsFixed(2)}',
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
