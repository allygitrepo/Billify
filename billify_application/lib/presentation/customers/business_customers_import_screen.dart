import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/business_model.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusinessCustomersImportScreen extends ConsumerStatefulWidget {
  const BusinessCustomersImportScreen({super.key});

  @override
  ConsumerState<BusinessCustomersImportScreen> createState() =>
      _BusinessCustomersImportScreenState();
}

class _BusinessCustomersImportScreenState
    extends ConsumerState<BusinessCustomersImportScreen> {
  String? _selectedSourceBusinessId;
  List<Customer> _sourceCustomers = [];
  final Set<String> _selectedPhoneNumbers = {};
  bool _isLoadingSource = false;
  bool _isImporting = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSourceBusiness();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initSourceBusiness() {
    final businessState = ref.read(businessProvider);
    final currentId = businessState.currentBusinessId;
    final otherBusinesses =
        businessState.businesses.where((b) => b.id != currentId).toList();

    if (otherBusinesses.isNotEmpty) {
      _selectedSourceBusinessId = otherBusinesses.first.id;
      _loadCustomersFromSource(_selectedSourceBusinessId!);
    }
  }

  Future<void> _loadCustomersFromSource(String businessId) async {
    setState(() {
      _isLoadingSource = true;
      _sourceCustomers = [];
      _selectedPhoneNumbers.clear();
    });

    try {
      final customers = await ref
          .read(customerProvider.notifier)
          .fetchCustomersFromBusiness(businessId);
      if (mounted) {
        setState(() {
          _sourceCustomers = customers;
          _isLoadingSource = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSource = false;
        });
        AppFeedback.showError(
          context,
          'Failed to load customers from selected business: $e',
        );
      }
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.trim().isEmpty) return _sourceCustomers;
    final q = _searchQuery.toLowerCase().trim();
    return _sourceCustomers.where((c) {
      final name = c.name.toLowerCase();
      final phone = _normalizePhone(c.phoneNumber);
      final city = (c.city ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || city.contains(q);
    }).toList();
  }

  Future<void> _importSelected() async {
    if (_selectedPhoneNumbers.isEmpty) {
      AppFeedback.showWarning(context, 'Please select at least one customer.');
      return;
    }

    final currentCustomers = ref.read(customerProvider).value ?? [];
    final currentPhones =
        currentCustomers.map((c) => _normalizePhone(c.phoneNumber)).toSet();

    final toImport = _sourceCustomers.where((c) {
      final phone = _normalizePhone(c.phoneNumber);
      return _selectedPhoneNumbers.contains(phone) &&
          !currentPhones.contains(phone);
    }).toList();

    if (toImport.isEmpty) {
      AppFeedback.showWarning(
        context,
        'All selected customers already exist in the current business.',
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      await ref
          .read(customerProvider.notifier)
          .importCustomersFromBusiness(toImport);

      if (mounted) {
        setState(() => _isImporting = false);
        AppFeedback.showSuccess(
          context,
          'Successfully imported ${toImport.length} customer(s)!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        AppFeedback.showError(context, 'Import failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final currentId = businessState.currentBusinessId;
    final otherBusinesses =
        businessState.businesses.where((b) => b.id != currentId).toList();

    final currentCustomers = ref.watch(customerProvider).value ?? [];
    final currentPhones =
        currentCustomers.map((c) => _normalizePhone(c.phoneNumber)).toSet();

    final currentBusiness = businessState.businesses.firstWhere(
      (b) => b.id == currentId,
      orElse: () => BusinessModel(
        id: currentId ?? '',
        name: 'Current Business',
        phone: '',
        tax_percentage: 0,
        gst_percentage: 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Business'),
        actions: [
          if (_selectedPhoneNumbers.isNotEmpty && !_isImporting)
            TextButton(
              onPressed: _importSelected,
              child: Text(
                'IMPORT (${_selectedPhoneNumbers.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: otherBusinesses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Other Businesses Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You do not have any other businesses under this account to import customers from.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Source Business Selector Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Importing into: ${currentBusiness.name}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedSourceBusinessId,
                        decoration: InputDecoration(
                          labelText: 'Select Source Business',
                          prefixIcon: const Icon(Icons.store),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: otherBusinesses.map((b) {
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(
                              b.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _selectedSourceBusinessId) {
                            setState(() {
                              _selectedSourceBusinessId = val;
                            });
                            _loadCustomersFromSource(val);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Search & Select All Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                if (!_isLoadingSource && _sourceCustomers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CheckboxListTile(
                      dense: true,
                      title: Text(
                        'Select All (${_filteredCustomers.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: _filteredCustomers.isNotEmpty &&
                          _filteredCustomers
                              .where((c) => !currentPhones
                                  .contains(_normalizePhone(c.phoneNumber)))
                              .every((c) => _selectedPhoneNumbers
                                  .contains(_normalizePhone(c.phoneNumber))),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            for (final c in _filteredCustomers) {
                              final phone = _normalizePhone(c.phoneNumber);
                              if (!currentPhones.contains(phone)) {
                                _selectedPhoneNumbers.add(phone);
                              }
                            }
                          } else {
                            _selectedPhoneNumbers.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],

                // Customer List
                Expanded(
                  child: _isLoadingSource
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredCustomers.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No matching customers found'
                                    : 'No customers found in this business',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredCustomers.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final customer = _filteredCustomers[index];
                                final phone =
                                    _normalizePhone(customer.phoneNumber);
                                final isAlreadyAdded =
                                    currentPhones.contains(phone);
                                final isSelected =
                                    _selectedPhoneNumbers.contains(phone) ||
                                        isAlreadyAdded;

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: isAlreadyAdded
                                      ? null
                                      : (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedPhoneNumbers.add(phone);
                                            } else {
                                              _selectedPhoneNumbers.remove(phone);
                                            }
                                          });
                                        },
                                  secondary: CircleAvatar(
                                    backgroundImage: ImageUtils.providerFromBase64(
                                      customer.photo,
                                    ),
                                    child: customer.photo == null ||
                                            customer.photo!.isEmpty
                                        ? Text(
                                            customer.name.isNotEmpty
                                                ? customer.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    customer.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isAlreadyAdded
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        customer.phoneNumber,
                                        style: TextStyle(
                                          color: isAlreadyAdded
                                              ? Colors.grey
                                              : null,
                                        ),
                                      ),
                                      if (customer.city != null &&
                                          customer.city!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${customer.city}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isAlreadyAdded
                                                ? Colors.grey
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                      if (isAlreadyAdded) ...[
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Already Added',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
      bottomNavigationBar: otherBusinesses.isNotEmpty &&
              _selectedPhoneNumbers.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importSelected,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isImporting
                        ? 'Importing Customers...'
                        : 'Import (${_selectedPhoneNumbers.length}) Selected Customers',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
