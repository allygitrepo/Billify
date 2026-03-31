import 'dart:convert';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/presentation/billing/scanner_screen.dart';
import 'package:billify_application/presentation/business/business_setup_page.dart';
import 'package:billify_application/presentation/home/widgets/dashboard_components.dart';
import 'package:billify_application/presentation/settings/category_management_page.dart';
import 'package:billify_application/presentation/settings/settings_page.dart';
import 'package:billify_application/presentation/settings/uom_management_page.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/feature_settings_provider.dart';
import 'package:billify_application/providers/invoice_provider.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  bool _isWeeklyFilter = true;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      const ScannerScreen(), 
      const BusinessSetupPage(),
      const SettingsPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit == true) SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: pages[_currentIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showQuickMenu(context),
          backgroundColor: AppTheme.primaryTeal,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavButton(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan & Bill',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                const SizedBox(width: 48), // Space for FAB
                _NavButton(
                  icon: Icons.business_center_rounded,
                  label: 'Business',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final allInvoices = ref.watch(invoiceProvider);
    final invoiceNotifier = ref.watch(invoiceProvider.notifier);
    final allProducts = ref.watch(productProvider);
    final business = ref.watch(businessProvider).currentBusiness;
    final user = ref.watch(authProvider).user;

    // Trigger calculation
    final todaySales = invoiceNotifier.getTodaySales();
    final todayInvoiceCount = invoiceNotifier.getTodayInvoiceCount();
    final monthlyRevenue = invoiceNotifier.getMonthlyRevenue();
    final topSelling = invoiceNotifier.getTopSellingProducts(5);
    final lowStock = allProducts.where((p) => p.stock < 3).toList();

    final List<double> graphData = _isWeeklyFilter 
      ? invoiceNotifier.getWeeklySalesData()
      : invoiceNotifier.getMonthlySalesData();
    final List<String> graphLabels = _isWeeklyFilter 
      ? invoiceNotifier.getWeeklyLabels()
      : invoiceNotifier.getMonthlyLabels();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(invoiceProvider.notifier).loadInvoices(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(business: business, user: user),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: StatCard(
                        title: 'Sales',
                        value: '₹${todaySales.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        gradient: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: StatCard(
                        title: 'Invoices',
                        value: todayInvoiceCount.toString(),
                        icon: Icons.receipt_long,
                        gradient: const [Color(0xFF48CAE4), Color(0xFF00B4D8)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: StatCard(
                        title: 'Month',
                        value: '₹${(monthlyRevenue / 1000).toStringAsFixed(1)}k',
                        icon: Icons.trending_up,
                        gradient: const [AppTheme.primaryTeal, Color(0xFF00B4D8)],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Revenue Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Weekly', 
                          isSelected: _isWeeklyFilter, 
                          onTap: () => setState(() => _isWeeklyFilter = true)
                        ),
                        _FilterChip(
                          label: 'Monthly', 
                          isSelected: !_isWeeklyFilter, 
                          onTap: () => setState(() => _isWeeklyFilter = false)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PremiumRevenueGraph(
                data: graphData,
                labels: graphLabels,
                title: '',
              ),
              const SizedBox(height: 24),

              TopSellingList(products: topSelling, productModels: allProducts),
              const SizedBox(height: 24),

              StockAlertSection(lowStockProducts: lowStock),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Operations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _QuickMenuItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  color: Colors.orange,
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/stock-management'); },
                ),
                _QuickMenuItem(
                  icon: Icons.history,
                  label: 'History',
                  color: Colors.blue,
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/invoice-history'); },
                ),
                _QuickMenuItem(
                  icon: Icons.add_circle_outline,
                  label: 'Products',
                  color: Colors.purple,
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/products'); },
                ),
                if (ref.watch(featureSettingsProvider).isCategoryEnabled)
                  _QuickMenuItem(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    color: Colors.teal,
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementPage())); },
                  ),
                _QuickMenuItem(
                  icon: Icons.straighten,
                  label: 'UOM',
                  color: Colors.indigo,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const UomManagementPage())); },
                ),
                _QuickMenuItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: Colors.red,
                  onTap: () { Navigator.pop(context); ref.read(authProvider.notifier).logout(); Navigator.pushReplacementNamed(context, '/login'); },
                ),
              ],
            ),
            const SizedBox(height: 24),
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
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('EXIT', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final dynamic business;
  final dynamic user;

  const _HomeHeader({required this.business, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${user?.fullName ?? 'User'} 👋', style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 4),
              Text(business?.name ?? 'No Business Setup', 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: business?.logoBase64 != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(base64Decode(business!.logoBase64!), fit: BoxFit.cover),
                )
              : const Icon(Icons.business_rounded, color: AppTheme.primaryTeal, size: 28),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppTheme.primaryTeal : Colors.grey, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isSelected ? AppTheme.primaryTeal : Colors.grey, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ],
    );
  }
}
