import 'dart:convert';
import 'package:billify_application/data/models/customer_model.dart';
import 'package:billify_application/providers/customer_provider.dart';
import 'package:billify_application/presentation/customers/add_customer_bottom_sheet.dart';
import 'package:billify_application/presentation/customers/contacts_import_screen.dart';
import 'package:billify_application/presentation/customers/customer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  final bool showOnlyOutstanding;
  const CustomerListScreen({super.key, this.showOnlyOutstanding = false});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showOnlyOutstanding ? 'Khata (Ledger)' : 'Customers & Khata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsImportScreen()),
              );
            },
            tooltip: 'Import from Contacts',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const AddCustomerBottomSheet(),
              );
            },
            tooltip: 'Add New Customer',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(customerProvider.notifier).fetchCustomers();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) {
                ref.read(customerProvider.notifier).fetchCustomers(search: val);
              },
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (allCustomers) {
                final customers = widget.showOnlyOutstanding 
                  ? allCustomers.where((c) => c.remainingBalance != 0).toList()
                  : allCustomers;
                  
                if (customers.isEmpty) {
                  return Center(
                    child: Text(widget.showOnlyOutstanding 
                      ? 'No outstanding balances found.' 
                      : 'No customers found.'),
                  );
                }
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final bool owesMoney = customer.remainingBalance > 0;
                    final bool isSettled = customer.remainingBalance == 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: customer.photo != null &&
                                customer.photo!.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(
                                  base64Decode(customer.photo!),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                child: Text(customer.name[0].toUpperCase()),
                              ),
                        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(customer.phoneNumber),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${customer.remainingBalance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSettled
                                    ? Colors.grey
                                    : owesMoney
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                            Text(
                              isSettled
                                  ? 'Settled'
                                  : owesMoney
                                      ? 'You get'
                                      : 'You give',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerDetailScreen(customerId: customer.id!),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
