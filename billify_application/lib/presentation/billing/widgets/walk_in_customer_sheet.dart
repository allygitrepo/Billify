import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/presentation/widgets/custom_button.dart';
import 'package:billify/presentation/widgets/custom_text_field.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalkInCustomerSheet extends ConsumerStatefulWidget {
  final Function({
    int? customerId,
    required String customerType,
    String? name,
    String? phone,
    String? city,
    Customer? customer,
  })
  onProceed;

  const WalkInCustomerSheet({super.key, required this.onProceed});

  static Future<void> show(
    BuildContext context, {
    required Function({
      int? customerId,
      required String customerType,
      String? name,
      String? phone,
      String? city,
      Customer? customer,
    })
    onProceed,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: WalkInCustomerSheet(onProceed: onProceed),
        ),
      ),
    );
  }

  @override
  ConsumerState<WalkInCustomerSheet> createState() =>
      _WalkInCustomerSheetState();
}

class _WalkInCustomerSheetState extends ConsumerState<WalkInCustomerSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  bool _saveAsRegularCustomer = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleSkip() {
    Navigator.pop(context);
    widget.onProceed(
      customerId: null,
      customerType: 'WALKIN',
      name: null,
      phone: null,
      city: null,
      customer: null,
    );
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();

    // 1. If save as regular customer is selected
    if (_saveAsRegularCustomer) {
      if (name.isEmpty && phone.isEmpty) {
        AppFeedback.showError(
          context,
          'Please enter at least Name or Phone to create a customer',
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final businessId =
            ref.read(businessProvider).currentBusinessId ?? 'default';
        final newCustomer = Customer(
          businessId: businessId,
          name: name.isNotEmpty ? name : 'Customer $phone',
          phoneNumber: phone,
          city: city.isNotEmpty ? city : null,
        );

        final saved = await ref
            .read(customerProvider.notifier)
            .saveCustomer(newCustomer);

        if (!mounted) return;
        Navigator.pop(context);
        AppFeedback.showSuccess(context, 'Customer saved successfully');

        widget.onProceed(
          customerId: saved.id,
          customerType: 'REGULAR',
          name: saved.name,
          phone: saved.phoneNumber,
          city: saved.city,
          customer: saved,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppFeedback.showError(context, 'Failed to save customer: $e');
      }
      return;
    }

    // 2. Otherwise, proceed as Walk-in with optional manual inputs
    Navigator.pop(context);
    widget.onProceed(
      customerId: null,
      customerType: 'WALKIN',
      name: name.isNotEmpty ? name : null,
      phone: phone.isNotEmpty ? phone : null,
      city: city.isNotEmpty ? city : null,
      customer: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryTeal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Walk-in Customer Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add optional details or skip to proceed anonymously',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name Input
                CustomTextField(
                  controller: _nameController,
                  label: 'Customer Name (Optional)',
                  hint: 'e.g. Rahul Sharma',
                  prefixIcon: Icons.person_outline,
                  autofocus: true,
                ),
                const SizedBox(height: 14),

                // Phone Input
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  hint: 'e.g. 9876543210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                // City Input
                CustomTextField(
                  controller: _cityController,
                  label: 'City (Optional)',
                  hint: 'e.g. Ahmedabad / Surat',
                  prefixIcon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 16),

                // Save as Regular Customer Toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _saveAsRegularCustomer
                          ? AppTheme.primaryTeal
                          : Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Save as Regular Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Save to customer directory for future khata & records',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    activeTrackColor: AppTheme.primaryTeal,
                    value: _saveAsRegularCustomer,
                    onChanged: (val) {
                      setState(() => _saveAsRegularCustomer = val);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleSkip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: _saveAsRegularCustomer
                            ? 'SAVE & CONTINUE'
                            : 'CONTINUE TO INVOICE',
                        isLoading: _isLoading,
                        onPressed: _handleContinue,
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
  );
}
}
