import 'dart:convert';
import 'package:billify_application/data/models/customer_model.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/customer_provider.dart';
import 'package:billify_application/presentation/customers/add_customer_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactsImportScreen extends ConsumerStatefulWidget {
  const ContactsImportScreen({super.key});

  @override
  ConsumerState<ContactsImportScreen> createState() =>
      _ContactsImportScreenState();
}

class _ContactsImportScreenState extends ConsumerState<ContactsImportScreen> {
  List<Contact>? _contacts;
  final Set<String> _selectedPhones = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final status = await FlutterContacts.permissions.request(
        PermissionType.readWrite,
      );
      if (status == PermissionStatus.granted) {
        // Fetch all contacts with phones and thumbnails
        final contacts = await FlutterContacts.getAll(
          properties: {
            ContactProperty.name,
            ContactProperty.phone,
            ContactProperty.photoThumbnail,
          },
        );

        if (mounted) {
          setState(() {
            _contacts = contacts.where((c) => c.phones.isNotEmpty).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _contacts = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contacts = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching contacts: $e')),
        );
      }
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts ?? [];
    return (_contacts ?? []).where((c) {
      final String name = (c.displayName ?? '').toLowerCase();
      final phone = (c.phones.isEmpty || c.phones.first.number == null)
          ? ''
          : _normalizePhone(c.phones.first.number!);
      return name.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final existingCustomers = ref.watch(customerProvider).value ?? [];
    final existingPhones =
        existingCustomers.map((c) => _normalizePhone(c.phoneNumber)).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Contacts'),
        actions: [
          if (_selectedPhones.isNotEmpty)
            TextButton(
              onPressed: () => _importSelected(existingPhones),
              child: Text(
                'IMPORT (${_selectedPhones.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts == null
          ? const Center(
              child: Text('Please grant contacts permission in settings.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                    CheckboxListTile(
                      title: const Text('Select All'),
                      value:
                          _selectedPhones.length == _filteredContacts.length &&
                              _filteredContacts.isNotEmpty,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            for (final contact in _filteredContacts) {
                              if (contact.phones.isNotEmpty) {
                                final phone = _normalizePhone(contact.phones.first.number ?? '');
                                _selectedPhones.add(phone);
                              }
                            }
                          } else {
                            _selectedPhones.clear();
                            // Keep already added ones as effectively selected (though disabled in UI)
                            _selectedPhones.addAll(existingPhones);
                          }
                        });
                      },
                    ),
                const Divider(),
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? const Center(
                          child: Text('No contacts found with phone numbers.'),
                        )
                      : ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                final phone = contact.phones.isNotEmpty
                                    ? _normalizePhone(
                                        contact.phones.first.number ?? '')
                                    : '';
                                final isAlreadyAdded =
                                    existingPhones.contains(phone);

                                final isSelected =
                                    _selectedPhones.contains(phone) ||
                                        isAlreadyAdded;

                                final String dName =
                                    contact.displayName ?? 'No Name';

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: isAlreadyAdded
                                      ? null // Disable unchecking
                                      : (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedPhones.add(phone);
                                            } else {
                                              _selectedPhones.remove(phone);
                                            }
                                          });
                                        },
                        title: InkWell(
                          onTap: () => _showAddDetailsBottomSheet(contact),
                          child: Row(
                            children: [
                              Expanded(child: Text(dName)),
                              const Icon(
                                Icons.edit_note,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        subtitle: InkWell(
                          onTap: () => _showAddDetailsBottomSheet(contact),
                          child: Text(
                            (contact.phones.isNotEmpty &&
                                    contact.phones.first.number != null)
                                ? contact.phones.first.number!
                                : 'No number',
                          ),
                        ),
                        secondary: (contact.photo != null &&
                                contact.photo!.thumbnail != null)
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(
                                  contact.photo!.thumbnail!,
                                ),
                              )
                            : CircleAvatar(
                                child: Text(dName.isNotEmpty ? dName[0] : '?'),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddDetailsBottomSheet(Contact contact) {
    final businessIdString = ref.read(businessProvider).currentBusinessId;
    final int businessId = int.parse(businessIdString ?? '0');

    final tempCustomer = Customer(
      businessId: businessId,
      name: contact.displayName ?? '',
      phoneNumber: contact.phones.isNotEmpty
          ? contact.phones.first.number!.replaceAll(RegExp(r'\s+'), '')
          : '',
      photo: contact.photo != null
          ? base64Encode(contact.photo!.thumbnail!)
          : null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          AddCustomerBottomSheet(initialCustomer: tempCustomer),
    ).then((result) {
      if (result == true) {
        // Successully imported individually with details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer added with extra details!')),
          );
        }
      }
    });
  }

  Future<void> _importSelected(Set<String> existingPhones) async {
    setState(() => _isLoading = true);
    try {
      final businessIdString = ref.read(businessProvider).currentBusinessId;
      final int businessId = int.parse(businessIdString ?? '0');

      final List<Customer> toImport = [];
      for (final phone in _selectedPhones) {
        // Find the first contact in the master list that matches this phone
        final contact = (_contacts ?? []).firstWhere(
          (c) => c.phones.isNotEmpty && _normalizePhone(c.phones.first.number ?? '') == phone,
          orElse: () => Contact(),
        );
        
        if (contact.displayName != null) {
          // Skip if already added
          if (existingPhones.contains(phone)) continue;

          toImport.add(
            Customer(
              businessId: businessId,
              name: contact.displayName ?? 'No Name',
              phoneNumber: phone,
              photo: contact.photo != null
                  ? base64Encode(contact.photo!.thumbnail!)
                  : null,
            ),
          );
        }
      }

      if (toImport.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new customers to import.')),
          );
        }
      } else {
        await ref.read(customerProvider.notifier).bulkImport(toImport);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${toImport.length} new customers imported successfully'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
