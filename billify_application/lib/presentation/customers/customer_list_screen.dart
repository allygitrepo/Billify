import 'package:billify/core/routes/app_routes.dart';
import 'package:billify/core/routes/route_arguments.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:billify/presentation/customers/add_customer_bottom_sheet.dart';
import 'package:billify/presentation/widgets/app_banner_ad.dart';
import 'package:billify/presentation/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  final bool showOnlyOutstanding;
  const CustomerListScreen({super.key, this.showOnlyOutstanding = false});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showOnlyOutstanding ? 'Khata (Ledger)' : 'Customers & Khata',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.businessCustomersImport);
            },
            tooltip: 'Import from Another Business',
          ),
          IconButton(
            icon: const Icon(Icons.import_contacts),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.contactsImport);
            },
            tooltip: 'Import from Contacts',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: const AddCustomerBottomSheet(),
                  ),
                ),
              );
            },
            tooltip: 'Add New Customer',
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        child: AppBannerAd(),
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search by name or phone...',
            onChanged: (val) {
              ref.read(customerProvider.notifier).fetchCustomers(search: val);
            },
            onClear: () {
              ref.read(customerProvider.notifier).fetchCustomers();
            },
          ),
          Expanded(
            child: customersAsync.when(
              data: (allCustomers) {
                final customers = widget.showOnlyOutstanding
                    ? allCustomers
                          .where((c) => c.remainingBalance != 0)
                          .toList()
                    : allCustomers;

                if (customers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.showOnlyOutstanding
                                ? Icons.account_balance_wallet_outlined
                                : Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.showOnlyOutstanding
                                ? 'No outstanding balances found.'
                                : 'No customers found for this business.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!widget.showOnlyOutstanding) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.businessCustomersImport,
                                    );
                                  },
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                                  label: const Text('Import from Business'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.contactsImport,
                                    );
                                  },
                                  icon: const Icon(Icons.import_contacts, size: 18),
                                  label: const Text('Import Contacts'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      useRootNavigator: true,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Align(
                                        alignment: Alignment.bottomCenter,
                                        child: ConstrainedBox(
                                          constraints:
                                              const BoxConstraints(maxWidth: 600),
                                          child: const AddCustomerBottomSheet(),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Customer'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final bool owesMoney = customer.remainingBalance > 0;
                    final bool isSettled = customer.remainingBalance == 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading:
                            customer.photo != null && customer.photo!.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(
                                  ImageUtils.decodeBase64(customer.photo!),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                child: Text(customer.name[0].toUpperCase()),
                              ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(customer.phoneNumber),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.blue),
                              onPressed: () async {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: customer.phoneNumber,
                                );
                                if (await canLaunchUrl(launchUri)) {
                                  await launchUrl(launchUri);
                                } else {
                                  if (context.mounted) {
                                    AppFeedback.showError(
                                      context,
                                      'Could not launch dialer',
                                    );
                                  }
                                }
                              },
                              tooltip: 'Call Customer',
                            ),
                            const SizedBox(width: 8),
                            Column(
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
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.customerDetail,
                            arguments: CustomerDetailRouteArgs(
                              customerId: customer.id!,
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
