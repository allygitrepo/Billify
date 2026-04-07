import 'package:billify_application/providers/customer_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final int? customerId;
  const AddPaymentScreen({super.key, this.customerId});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  int? _selectedCustomerId;
  String _paymentType = 'Receive'; // 'Receive' (Debit), 'Give' (Credit)
  String _paymentMethod = 'Cash';

  final List<String> _methods = ['Cash', 'UPI', 'Bank', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              Row(
                children: [
                   Expanded(
                    child: _typeCard('Receive', Icons.call_received, Colors.green),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeCard('Give', Icons.call_made, Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              // Customer Dropdown
              customersAsync.when(
                data: (customers) => DropdownButtonFormField<int>(
                  value: _selectedCustomerId,
                  decoration: const InputDecoration(
                    labelText: 'Select Customer',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: customers.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: widget.customerId != null ? null : (val) => setState(() => _selectedCustomerId = val),
                  validator: (val) => val == null ? 'Please select a customer' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Error loading customers: $e'),
              ),
              const SizedBox(height: 15),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (val) => (val == null || double.tryParse(val) == null) ? 'Invalid amount' : null,
              ),
              const SizedBox(height: 15),

              // Method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wallet),
                ),
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 15),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 30),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _paymentType == 'Receive' ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _savePayment,
                child: Text(
                  _paymentType == 'Receive' ? 'Receive Payment' : 'Add Credit Entry',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeCard(String title, IconData icon, Color color) {
    final bool isSelected = _paymentType == title;
    return GestureDetector(
      onTap: () => setState(() => _paymentType = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3)),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) return;

    try {
      final repo = ref.read(customerRepositoryProvider);
      final data = {
        'customer_id': _selectedCustomerId,
        'amount': double.parse(_amountController.text),
        'payment_method': _paymentMethod,
        'note': _noteController.text,
      };

      if (_paymentType == 'Receive') {
        await repo.receivePayment(data);
      } else {
        await repo.givePayment(data);
      }

      await ref.read(customerProvider.notifier).fetchCustomers();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction recorded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
