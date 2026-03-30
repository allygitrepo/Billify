import 'dart:convert';
import 'package:billify_application/providers/invoice_provider.dart';
import 'package:flutter/services.dart';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/presentation/business/business_setup_page.dart';
import 'package:billify_application/presentation/settings/settings_page.dart';
import 'package:billify_application/presentation/widgets/section_card.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _HomeDashboard(),
      const BusinessSetupPage(),
      const SettingsPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppTheme.primaryTeal,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              activeIcon: Icon(Icons.business),
              label: 'Business',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit Billify?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXIT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final businessState = ref.watch(businessProvider);
    final invoiceState = ref.watch(invoiceProvider);
    final business = businessState.currentBusiness;
    final user = authState.user;

    // Calculate Dashboard Stats
    final totalInvoices = invoiceState.length;
    final totalCollected = invoiceState.fold(0.0, (sum, e) => sum + e.total);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.fullName ?? 'User'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              business?.name ?? 'No Business Setup',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (businessState.businesses.length > 1)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 28,
                              ),
                              offset: const Offset(0, 48),
                              onSelected: (id) => ref
                                  .read(businessProvider.notifier)
                                  .switchBusiness(id),
                              itemBuilder: (context) => businessState.businesses
                                  .map(
                                    (b) => PopupMenuItem(
                                      value: b.id,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppTheme.softGrey,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              image: b.logoBase64 != null
                                                  ? DecorationImage(
                                                      image: MemoryImage(
                                                        base64Decode(
                                                          b.logoBase64!,
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: b.logoBase64 == null
                                                ? const Icon(
                                                    Icons.business,
                                                    size: 16,
                                                    color: AppTheme.primaryTeal,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              b.name,
                                              style: TextStyle(
                                                fontWeight:
                                                    b.id ==
                                                        businessState
                                                            .currentBusinessId
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color:
                                                    b.id ==
                                                        businessState
                                                            .currentBusinessId
                                                    ? AppTheme.primaryTeal
                                                    : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (b.id ==
                                              businessState.currentBusinessId)
                                            const Icon(
                                              Icons.check,
                                              color: AppTheme.primaryTeal,
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (business?.logoBase64 != null)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(business!.logoBase64!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  const CircleAvatar(
                    backgroundColor: AppTheme.primaryTeal,
                    radius: 25,
                    child: Icon(Icons.business, color: Colors.white, size: 30),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            SectionCard(
              title: 'Quick Summary',
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Total Invoices',
                    value: totalInvoices.toString(),
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                  const Divider(height: 32),
                  _SummaryRow(
                    label: 'Outstanding Amount',
                    value: '₹ 0.00',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  const Divider(height: 32),
                  _SummaryRow(
                    label: 'Total Collected',
                    value: '₹ ${totalCollected.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Actions',
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3, // Increased height slightly to prevent overflow
                children: [
                  _ActionCard(
                    title: 'Scan & Bill',
                    icon: Icons.qr_code_scanner,
                    color: AppTheme.primaryTeal,
                    onTap: () => Navigator.pushNamed(context, '/scanner'),
                  ),
                  _ActionCard(
                    title: 'Add Product',
                    icon: Icons.add_box_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/add-product'),
                  ),
                  _ActionCard(
                    title: 'History',
                    icon: Icons.history,
                    color: Colors.orange,
                    onTap: () =>
                        Navigator.pushNamed(context, '/invoice-history'),
                  ),
                  _ActionCard(
                    title: 'Inventory Management',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.purple,
                    onTap: () =>
                        Navigator.pushNamed(context, '/stock-management'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
