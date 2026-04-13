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
import 'package:billify_application/providers/registration_provider.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/presentation/widgets/error_handler.dart';
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
        _gstNumberController.text = business.gstin ?? '';
        _addressController.text = business.address ?? '';
        _taxController.text = business.tax_percentage.toString();
        _gstPercentController.text = business.gst_percentage.toString();

        _invoicePrefixController.text = business.invoice_prefix;
        _nextInvoiceNumberController.text = business.starting_invoice_number
            .toString();

        _logoBase64 = business.business_logo;
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

  bool get _isRegistrationMode {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('isRegistration')) {
      return args['isRegistration'] as bool;
    }
    return false;
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      if (_isRegistrationMode) {
        // Step 2 of Registration
        await ref
            .read(registrationProvider.notifier)
            .updateBusinessStep(
              businessName: _nameController.text,
              businessPhone: _phoneController.text,
              gstin: _gstNumberController.text,
              address: _addressController.text,
              logo: _logoBase64,
              taxPercentage: double.tryParse(_taxController.text),
              gstPercentage: double.tryParse(_gstPercentController.text),
              invoicePrefix: _invoicePrefixController.text,
              startingNumber: int.tryParse(_nextInvoiceNumberController.text),
            );

        final registrationData = ref.read(registrationProvider);
        if (registrationData != null) {
          await ref
              .read(authProvider.notifier)
              .register(registrationData.toJson());

          final authState = ref.read(authProvider);
          if (authState.error == null && mounted) {
            await ref.read(registrationProvider.notifier).clear();
            ErrorHandler.showSuccessSnackBar(context, 'Registration successful! Please login.');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          } else if (authState.error != null && mounted) {
            ErrorHandler.showErrorSnackBar(context, authState.errorObject ?? authState.error);
          }
        }
      } else {
        // Normal Business Update/Create
        final business = BusinessModel(
          id:
              _activeBusinessId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          gstin: _gstNumberController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          tax_percentage: double.tryParse(_taxController.text) ?? 0.0,
          gst_percentage: double.tryParse(_gstPercentController.text) ?? 0.0,
          invoice_prefix: _invoicePrefixController.text.isEmpty
              ? 'INV-'
              : _invoicePrefixController.text,
          starting_invoice_number:
              int.tryParse(_nextInvoiceNumberController.text) ?? 1,
          business_logo: _logoBase64,
        );

        final isFirstBusiness = ref.read(businessProvider).businesses.isEmpty;
        await ref.read(businessProvider.notifier).saveBusiness(business);

        if (mounted) {
          if (isFirstBusiness) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            setState(() => _isFormView = false);
          }
        }
      }
      setState(() => _isLoading = false);
    }
  }

  void _editBusiness(BusinessModel business) {
    setState(() {
      _isFormView = true;
      _activeBusinessId = business.id;
      _nameController.text = business.name;
      _phoneController.text = business.phone;
      _gstNumberController.text = business.gstin ?? '';
      _addressController.text = business.address ?? '';
      _taxController.text = business.tax_percentage.toString();
      _gstPercentController.text = business.gst_percentage.toString();
      _invoicePrefixController.text = business.invoice_prefix;
      _nextInvoiceNumberController.text = business.starting_invoice_number
          .toString();
      _logoBase64 = business.business_logo;
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

  void _showSwitchConfirmation(
    BuildContext context,
    BusinessModel targetBusiness,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Business?'),
        content: Text(
          'Do you want to switch to "${targetBusiness.name}"? Dashboard data will refresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(businessProvider.notifier)
                  .switchBusiness(targetBusiness.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Switched to ${targetBusiness.name}')),
                );
              }
            },
            child: const Text(
              'SWITCH',
              style: TextStyle(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegistrationMode
              ? 'Business Setup (Step 2/2)'
              : (_isFormView
                    ? (_activeBusinessId == null
                          ? 'New Business'
                          : 'Edit Business')
                    : 'My Businesses'),
        ),
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
          child:
              _isRegistrationMode ||
                  _isFormView ||
                  businessState.businesses.isEmpty
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
                  image: business.business_logo != null
                      ? DecorationImage(
                          image: MemoryImage(
                            base64Decode(business.business_logo!),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: business.business_logo == null
                    ? const Icon(
                        Icons.business,
                        size: 30,
                        color: AppTheme.primaryTeal,
                      )
                    : null,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      business.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryTeal),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(business.phone),
                  if (business.gstin != null && business.gstin!.isNotEmpty)
                    Text('GST: ${business.gstin}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.grey),
                onPressed: () => _editBusiness(business),
              ),
              onTap: isCurrent
                  ? null
                  : () => _showSwitchConfirmation(context, business),
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
                    onImageSelected: (base64) =>
                        setState(() => _logoBase64 = base64),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Business Name',
                    hint: 'e.g. Allysoft Solutions',
                    prefixIcon: Icons.business,
                    validator: (v) =>
                        Validators.validateRequired(v, 'Business Name'),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Business Phone',
                    prefixIcon: Icons.phone,
                    // validator: Validators.validatePhone,
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
              text: _isRegistrationMode
                  ? 'COMPLETE REGISTRATION'
                  : (_activeBusinessId == null
                        ? 'SAVE BUSINESS PROFILE'
                        : 'UPDATE BUSINESS PROFILE'),
              onPressed: _handleSave,
              isLoading: _isLoading,
            ),
            if (_activeBusinessId != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(businessProvider.notifier)
                      .deleteBusiness(_activeBusinessId!);
                  setState(() => _isFormView = false);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'DELETE BUSINESS',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
