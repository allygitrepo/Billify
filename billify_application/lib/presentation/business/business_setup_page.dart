import 'dart:convert';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/core/utils/validators.dart';
import 'package:billify_application/providers/state/business_state.dart';
import 'package:billify_application/data/models/business_model.dart';
import 'package:billify_application/presentation/widgets/custom_button.dart';
import 'package:billify_application/presentation/widgets/custom_text_field.dart';
import 'package:billify_application/presentation/widgets/image_picker_widget.dart';
import 'package:billify_application/presentation/widgets/section_card.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusinessSetupPage extends ConsumerStatefulWidget {
  const BusinessSetupPage({super.key});

  @override
  ConsumerState<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends ConsumerState<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxController = TextEditingController();
  final _gstPercentController = TextEditingController();
  final _invoicePrefixController = TextEditingController();
  final _nextInvoiceNumberController = TextEditingController();
  String? _logoBase64;
  bool _isLoading = false;
  String? _activeBusinessId;
  bool _isFormView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentBusiness();
    });
  }

  void _loadCurrentBusiness() {
    final business = ref.read(businessProvider).currentBusiness;
    if (business != null) {
      setState(() {
        _activeBusinessId = business.id;
        _nameController.text = business.name;
        _phoneController.text = business.phone;
        _gstNumberController.text = business.gstNumber ?? '';
        _addressController.text = business.address ?? '';
        _taxController.text = business.tax.toString();
        _gstPercentController.text = business.gst.toString();
        
        // Defensive assignment for migration to handle cases where 
        // older models might lack these properties at runtime
        _invoicePrefixController.text = (business.invoicePrefix as dynamic) ?? 'INV-';
        _nextInvoiceNumberController.text = ((business.nextInvoiceNumber as dynamic) ?? 1).toString();
        
        _logoBase64 = business.logoBase64;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gstNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    _gstPercentController.dispose();
    _invoicePrefixController.dispose();
    _nextInvoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final business = BusinessModel(
        id: _activeBusinessId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        gstNumber: _gstNumberController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        tax: double.tryParse(_taxController.text) ?? 0.0,
        gst: double.tryParse(_gstPercentController.text) ?? 0.0,
        invoicePrefix: _invoicePrefixController.text.isEmpty ? 'INV-' : _invoicePrefixController.text,
        nextInvoiceNumber: int.tryParse(_nextInvoiceNumberController.text) ?? 1,
        logoBase64: _logoBase64,
      );

      final isFirstBusiness = ref.read(businessProvider).businesses.isEmpty;
      await ref.read(businessProvider.notifier).saveBusiness(business);
      setState(() => _isLoading = false);

      if (mounted) {
        if (isFirstBusiness) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() => _isFormView = false);
        }
      }
    }
  }

  void _editBusiness(BusinessModel business) {
    setState(() {
      _isFormView = true;
      _activeBusinessId = business.id;
      _nameController.text = business.name;
      _phoneController.text = business.phone;
      _gstNumberController.text = business.gstNumber ?? '';
      _addressController.text = business.address ?? '';
      _taxController.text = business.tax.toString();
      _gstPercentController.text = business.gst.toString();
      _invoicePrefixController.text = business.invoicePrefix;
      _nextInvoiceNumberController.text = business.nextInvoiceNumber.toString();
      _logoBase64 = business.logoBase64;
    });
  }

  void _addNewBusiness() {
    setState(() {
      _isFormView = true;
      _activeBusinessId = null;
      _nameController.clear();
      _phoneController.clear();
      _gstNumberController.clear();
      _addressController.clear();
      _taxController.clear();
      _gstPercentController.clear();
      _invoicePrefixController.text = 'INV-';
      _nextInvoiceNumberController.text = '1';
      _logoBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFormView
            ? (_activeBusinessId == null ? 'New Business' : 'Edit Business')
            : 'My Businesses'),
        leading: _isFormView && businessState.businesses.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _isFormView = false),
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isFormView || businessState.businesses.isEmpty
              ? _buildForm(context)
              : _buildBusinessList(context, businessState),
        ),
      ),
      floatingActionButton: !_isFormView && businessState.businesses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addNewBusiness,
              label: const Text('Add Business'),
              icon: const Icon(Icons.add),
              backgroundColor: AppTheme.primaryTeal,
            )
          : null,
    );
  }

  Widget _buildBusinessList(BuildContext context, BusinessState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: state.businesses.length,
      itemBuilder: (context, index) {
        final business = state.businesses[index];
        final isCurrent = business.id == state.currentBusinessId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: isCurrent ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isCurrent
                  ? const BorderSide(color: AppTheme.primaryTeal, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(12),
                  image: business.logoBase64 != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(business.logoBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: business.logoBase64 == null
                    ? const Icon(Icons.business, size: 30, color: AppTheme.primaryTeal)
                    : null,
              ),
              title: Text(
                business.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(business.phone),
                  if (business.gstNumber != null && business.gstNumber!.isNotEmpty)
                    Text('GST: ${business.gstNumber}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editBusiness(business),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SectionCard(
              child: Column(
                children: [
                  ImagePickerWidget(
                    label: 'Business Logo',
                    initialBase64: _logoBase64,
                    onImageSelected: (base64) => setState(() => _logoBase64 = base64),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Business Name',
                    hint: 'e.g. Allysoft Solutions',
                    prefixIcon: Icons.business,
                    validator: (v) => Validators.validateRequired(v, 'Business Name'),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Business Phone',
                    prefixIcon: Icons.phone,
                    validator: Validators.validatePhone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _gstNumberController,
                    label: 'GST Number (Optional)',
                    prefixIcon: Icons.confirmation_number_outlined,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Business Address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Tax Configuration',
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _taxController,
                      label: 'Tax %',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.percent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _gstPercentController,
                      label: 'GST %',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.receipt_long,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Invoice Configuration',
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _invoicePrefixController,
                      label: 'Invoice Prefix',
                      hint: 'e.g. INV-',
                      prefixIcon: Icons.tag,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _nextInvoiceNumberController,
                      label: 'Starting No.',
                      hint: 'e.g. 1001',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.format_list_numbered,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: _activeBusinessId == null ? 'SAVE BUSINESS PROFILE' : 'UPDATE BUSINESS PROFILE',
              onPressed: _handleSave,
              isLoading: _isLoading,
            ),
            if (_activeBusinessId != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  ref.read(businessProvider.notifier).deleteBusiness(_activeBusinessId!);
                  setState(() => _isFormView = false);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('DELETE BUSINESS', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
