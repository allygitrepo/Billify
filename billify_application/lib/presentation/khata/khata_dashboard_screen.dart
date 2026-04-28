import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/customer_model.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:billify/presentation/customers/customer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KhataDashboardScreen extends ConsumerStatefulWidget {
  const KhataDashboardScreen({super.key});

  @override
  ConsumerState<KhataDashboardScreen> createState() =>
      _KhataDashboardScreenState();
}

class _KhataDashboardScreenState extends ConsumerState<KhataDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All'; // 'All', 'You Get', 'You Give'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Khata Dashboard'), elevation: 0),
      body: customersAsync.when(
        data: (customers) {
          final summary = _calculateSummary(customers);
          final filteredCustomers = _getFilteredCustomers(customers);

          return Column(
            children: [
              _buildSummaryHeader(summary),
              _buildFilterBar(),
              _buildSearchField(),
              Expanded(
                child: filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return _KhataCustomerTile(customer: customer);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Map<String, double> _calculateSummary(List<Customer> customers) {
    double totalGet = 0; // Customers owe us
    double totalGive = 0; // We owe customers

    for (var c in customers) {
      if (c.remainingBalance > 0) {
        totalGet += c.remainingBalance;
      } else if (c.remainingBalance < 0) {
        totalGive += c.remainingBalance.abs();
      }
    }
    return {'get': totalGet, 'give': totalGive};
  }

  List<Customer> _getFilteredCustomers(List<Customer> customers) {
    final query = _searchController.text.toLowerCase();
    return customers
        .where((c) {
          final matchesSearch =
              c.name.toLowerCase().contains(query) ||
              c.phoneNumber.contains(query);
          if (!matchesSearch) return false;

          if (_filter == 'You Get') return c.remainingBalance > 0;
          if (_filter == 'You Give') return c.remainingBalance < 0;
          return true; // 'All' - but only those with balance for a true "Khata" dashboard
        })
        .where((c) => c.remainingBalance != 0 || _filter == 'All')
        .toList();
  }

  Widget _buildSummaryHeader(Map<String, double> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'You will get',
              amount: summary['get']!,
              color: Colors.green,
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              label: 'You will give',
              amount: summary['give']!,
              color: Colors.red,
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: ['All', 'You Get', 'You Give'].map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _filter = f);
              },
              selectedColor: AppTheme.primaryTeal.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search customers...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Khata entries found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KhataCustomerTile extends StatelessWidget {
  final Customer customer;

  const _KhataCustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final bool owesMoney = customer.remainingBalance > 0;
    final color = owesMoney ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(color: AppTheme.primaryTeal),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          customer.phoneNumber,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${customer.remainingBalance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              owesMoney ? 'You will get' : 'You will give',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CustomerDetailScreen(customerId: customer.id!),
            ),
          );
        },
      ),
    );
  }
}
