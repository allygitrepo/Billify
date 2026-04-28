import 'dart:convert';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/presentation/customers/contacts_import_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCustomerBottomSheet extends ConsumerStatefulWidget {
  final Customer? initialCustomer;
  const AddCustomerBottomSheet({super.key, this.initialCustomer});

  @override
  ConsumerState<AddCustomerBottomSheet> createState() =>
      _AddCustomerBottomSheetState();
}

class _AddCustomerBottomSheetState
    extends ConsumerState<AddCustomerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _openingBalanceController;
  late TextEditingController _cityController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCustomer?.name);
    _phoneController = TextEditingController(
      text: widget.initialCustomer?.phoneNumber,
    );
    _openingBalanceController = TextEditingController(
      text: widget.initialCustomer?.openingBalance.toString() ?? '0.0',
    );
    _cityController = TextEditingController(text: widget.initialCustomer?.city);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _openingBalanceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialCustomer?.id != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Customer Details' : 'Add New Customer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (!isEditing)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactsImportScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.import_contacts),
                  label: const Text('Quickly Import from Contacts'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (widget.initialCustomer?.photo != null &&
                  widget.initialCustomer!.photo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: MemoryImage(
                        ImageUtils.decodeBase64(widget.initialCustomer!.photo!),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Phone is required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _openingBalanceController,
                keyboardType: TextInputType.number,
                enabled:
                    !isEditing, // Typically opening balance shouldn't be edited directly here
                decoration: InputDecoration(
                  labelText: 'Opening Balance (Khata)',
                  helperText: isEditing
                      ? 'Edit from Ledger for adjustments'
                      : 'Positive = Customer owes you (+), Negative = You owe (-)',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City (Optional)',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _saveCustomer,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Customer' : 'Save Customer',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final businessIdString = ref.read(businessProvider).currentBusinessId;
      final int businessId = int.parse(businessIdString ?? '0');

      final customer = Customer(
        id: widget.initialCustomer?.id, // Preserve ID if editing
        businessId: businessId,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        openingBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        remainingBalance:
            widget.initialCustomer?.remainingBalance ??
            0.0, // Fail-safe: don't wipe out balance on edit!
        city: _cityController.text,
        photo: widget.initialCustomer?.photo, // Preserve photo
        status: widget.initialCustomer?.status ?? 'active',
      );

      await ref.read(customerProvider.notifier).saveCustomer(customer);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate change
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialCustomer != null
                  ? 'Customer updated successfully'
                  : 'Customer saved successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
