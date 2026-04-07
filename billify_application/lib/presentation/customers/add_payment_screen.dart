import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/customer_model.dart';
import 'package:billify_application/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final Customer customer;
  final bool isCredit; // true: I Gave (Customer owes), false: I Got (Customer paid)

  const AddPaymentScreen({
    super.key,
    required this.customer,
    required this.isCredit,
  });

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text);
      await ref.read(customerProvider.notifier).recordPayment(
            customerId: widget.customer.id!,
            amount: amount,
            isCredit: widget.isCredit,
            note: _noteController.text.trim(),
            date: _selectedDate,
            method: _paymentMethod,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isCredit ? 'Credit entry added' : 'Payment recorded',
            ),
            backgroundColor: widget.isCredit ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCredit ? Colors.red : Colors.green;
    final title = widget.isCredit ? 'You Gave' : 'You Got';

    return Scaffold(
      appBar: AppBar(
        title: Text('$title to ${widget.customer.name}'),
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Text(
                'Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withOpacity(0.3)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  if (double.tryParse(val) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Note Input
              const Text(
                'Note / Remark',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Enter details (e.g. For Milk, Cash, Invoices...)',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today, color: color),
                title: const Text('Date'),
                subtitle: Text(DateFormat('dd MMM, yyyy').format(_selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const Divider(),

              // Payment Method
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.payment, color: color),
                title: const Text('Payment Method'),
                subtitle: Text(_paymentMethod),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) => setState(() => _paymentMethod = val),
                  itemBuilder: (context) => ['Cash', 'Online / UPI', 'Bank Transfer', 'Other']
                      .map((m) => PopupMenuItem(value: m, child: Text(m)))
                      .toList(),
                ),
              ),
              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'SAVE $title'.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
