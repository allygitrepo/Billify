import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/presentation/billing/scanner_screen.dart';
import 'package:billify/presentation/business/business_setup_page.dart';
import 'package:billify/presentation/home/widgets/dashboard_components.dart';
import 'package:billify/presentation/settings/category_management_page.dart';
import 'package:billify/presentation/settings/settings_page.dart';
import 'package:billify/presentation/settings/uom_management_page.dart';
import 'package:billify/presentation/widgets/full_screen_image_viewer.dart';
import 'package:billify/presentation/khata/khata_dashboard_screen.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/feature_settings_provider.dart';
import 'package:billify/providers/invoice_provider.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/presentation/analytics/analytics_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

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
    final authState = ref.watch(authProvider);
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
        floatingActionButton:
            authState.hasPermission(
              PermissionModule.billing,
              PermissionAction.view,
            )
            ? FloatingActionButton(
                onPressed: () => _showQuickMenu(context),
                backgroundColor: AppTheme.primaryTeal,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
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
                if (authState.hasPermission(
                  PermissionModule.billing,
                  PermissionAction.view,
                ))
                  _NavButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan & Bill',
                    isSelected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                if (authState.hasPermission(
                  PermissionModule.billing,
                  PermissionAction.view,
                ))
                  const SizedBox(width: 48), // Space for FAB
                if (authState.hasPermission(
                  PermissionModule.systemSettings,
                  PermissionAction.view,
                ))
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
    final allProducts = ref.watch(productsListProvider);
    final business = ref.watch(businessProvider).currentBusiness;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Trigger calculation
    final todaySales = invoiceNotifier.getTodaySales();
    final todayInvoiceCount = invoiceNotifier.getTodayInvoiceCount();
    final monthlyRevenue = invoiceNotifier.getMonthlyRevenue();
    final topSelling = invoiceNotifier.getTopSellingProducts(5);
    final lowStock = allProducts.where((p) => p.totalStock < 3).toList();

    final List<double> graphData = _isWeeklyFilter
        ? invoiceNotifier.getWeeklySalesData()
        : invoiceNotifier.getMonthlySalesData();
    final List<String> graphLabels = _isWeeklyFilter
        ? invoiceNotifier.getWeeklyLabels()
        : invoiceNotifier.getMonthlyLabels();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(authProvider.notifier).reloadPermissions(),
            ref.read(invoiceProvider.notifier).loadInvoices(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(
                business: business,
                user: user,
                onTap: () => _showBusinessSwitcher(context),
              ),
              const SizedBox(height: 20),

              // Show Quick Actions module grid only for staff users (Owners already have the full dashboard)
              if (!authState.isOwnerOrAdmin) ...[
                _buildModulesGrid(context, authState),
                const SizedBox(height: 24),
              ],

              if (authState.hasPermission(
                PermissionModule.dashboard,
                PermissionAction.view,
              )) ...[
                const Text(
                  'Sales Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: [
                    StatCard(
                      title: 'Today\'s Sales',
                      value: '₹${todaySales.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      gradient: const [
                        Color(0xFF00B4D8),
                        Color(0xFF0077B6),
                      ],
                    ),
                    StatCard(
                      title: 'Invoices',
                      value: todayInvoiceCount.toString(),
                      icon: Icons.receipt_long,
                      gradient: const [
                        Color(0xFF48CAE4),
                        Color(0xFF00B4D8),
                      ],
                    ),
                    StatCard(
                      title: 'Month',
                      value: monthlyRevenue >= 1000
                          ? '₹${(monthlyRevenue / 1000).toStringAsFixed(1)}k'
                          : '₹${monthlyRevenue.toStringAsFixed(0)}',
                      icon: Icons.trending_up,
                      gradient: const [
                        AppTheme.primaryTeal,
                        Color(0xFF00B4D8),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              if (authState.hasPermission(
                PermissionModule.analytics,
                PermissionAction.view,
              )) ...[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Text(
                      'Revenue Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FilterChip(
                            label: 'Weekly',
                            isSelected: _isWeeklyFilter,
                            onTap: () => setState(() => _isWeeklyFilter = true),
                          ),
                          _FilterChip(
                            label: 'Monthly',
                            isSelected: !_isWeeklyFilter,
                            onTap: () =>
                                setState(() => _isWeeklyFilter = false),
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
              ],

              if (authState.hasPermission(
                PermissionModule.reports,
                PermissionAction.view,
              )) ...[
                TopSellingList(
                  products: topSelling,
                  productModels: allProducts,
                ),
                const SizedBox(height: 24),
              ],

              if (authState.hasPermission(
                PermissionModule.inventory,
                PermissionAction.view,
              )) ...[
                StockAlertSection(lowStockProducts: lowStock),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context, AuthState authState) {
    final List<_ModuleItem> modules = [];

    if (authState.hasPermission(
      PermissionModule.billing,
      PermissionAction.view,
    )) {
      modules.add(_ModuleItem(
        title: 'Scan & Bill',
        subtitle: 'Quick POS billing',
        icon: Icons.qr_code_scanner_rounded,
        gradient: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
        onTap: () => Navigator.pushNamed(context, '/scanner'),
      ));
      modules.add(_ModuleItem(
        title: 'Invoices',
        subtitle: 'History & receipts',
        icon: Icons.receipt_long_rounded,
        gradient: const [Color(0xFF48CAE4), Color(0xFF023E8A)],
        onTap: () => Navigator.pushNamed(context, '/invoice-history'),
      ));
    }

    if (authState.hasPermission(
      PermissionModule.products,
      PermissionAction.view,
    )) {
      modules.add(_ModuleItem(
        title: 'Products',
        subtitle: 'Manage catalog',
        icon: Icons.inventory_2_rounded,
        gradient: const [Color(0xFF8338EC), Color(0xFF5A189A)],
        onTap: () => Navigator.pushNamed(context, '/products'),
      ));
    }

    if (authState.hasPermission(
      PermissionModule.inventory,
      PermissionAction.view,
    )) {
      modules.add(_ModuleItem(
        title: 'Inventory',
        subtitle: 'Stock levels',
        icon: Icons.warehouse_rounded,
        gradient: const [Color(0xFFFF9F1C), Color(0xFFF77F00)],
        onTap: () => Navigator.pushNamed(context, '/stock-management'),
      ));
    }

    if (ref.watch(featureSettingsProvider).isCategoryEnabled &&
        authState.hasPermission(
          PermissionModule.categories,
          PermissionAction.view,
        )) {
      modules.add(_ModuleItem(
        title: 'Categories',
        subtitle: 'Product groups',
        icon: Icons.category_rounded,
        gradient: const [Color(0xFF06D6A0), Color(0xFF058C42)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoryManagementPage(),
          ),
        ),
      ));
    }

    if (authState.hasPermission(
      PermissionModule.customers,
      PermissionAction.view,
    )) {
      modules.add(_ModuleItem(
        title: 'Customers',
        subtitle: 'Contacts & accounts',
        icon: Icons.people_alt_rounded,
        gradient: const [Color(0xFFFF006E), Color(0xFFC77DFF)],
        onTap: () => Navigator.pushNamed(context, '/customers'),
      ));
    }

    if (authState.hasPermission(
      PermissionModule.payments,
      PermissionAction.view,
    )) {
      modules.add(_ModuleItem(
        title: 'Khata / Ledger',
        subtitle: 'Credit & payments',
        icon: Icons.account_balance_wallet_rounded,
        gradient: const [Color(0xFF118AB2), Color(0xFF073B4C)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const KhataDashboardScreen(),
          ),
        ),
      ));
    }

    if (authState.hasPermission(
      PermissionModule.uom,
      PermissionAction.view,
    )) {
      modules.add(_ModuleItem(
        title: 'Units (UOM)',
        subtitle: 'Measurement units',
        icon: Icons.straighten_rounded,
        gradient: const [Color(0xFF3A86FF), Color(0xFF03045E)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const UomManagementPage(),
          ),
        ),
      ));
    }

    if (authState.hasPermission(
          PermissionModule.analytics,
          PermissionAction.view,
        ) ||
        authState.hasPermission(
          PermissionModule.reports,
          PermissionAction.view,
        )) {
      modules.add(_ModuleItem(
        title: 'Reports',
        subtitle: 'Sales & analytics',
        icon: Icons.analytics_rounded,
        gradient: const [Color(0xFF7209B7), Color(0xFF3F37C9)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AnalyticsDashboardScreen(),
          ),
        ),
      ));
    }

    if (authState.hasPermission(
      PermissionModule.userManagement,
      PermissionAction.view,
    )) {
      modules.add(_ModuleItem(
        title: 'Staff Management',
        subtitle: 'Users & roles',
        icon: Icons.badge_rounded,
        gradient: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
        onTap: () => Navigator.pushNamed(context, '/user-management'),
      ));
    }

    if (modules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.shield_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No Modules Assigned',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Your role does not currently have permissions enabled for any modules. Please contact your business owner to assign module permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            return _ModuleCard(item: modules[index]);
          },
        ),
      ],
    );
  }

  void _showBusinessSwitcher(BuildContext context) {
    final businessState = ref.read(businessProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Switch Business',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryTeal,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2); // Go to Business tab
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: businessState.businesses.length,
                itemBuilder: (context, index) {
                  final b = businessState.businesses[index];
                  final isCurrent = b.id == businessState.currentBusinessId;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: b.business_logo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                ImageUtils.decodeBase64(b.business_logo!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.business_rounded,
                              color: AppTheme.primaryTeal,
                            ),
                    ),
                    title: Text(
                      b.name,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: isCurrent
                        ? const Text(
                            'Active Now',
                            style: TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryTeal,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (!isCurrent) {
                        _showSwitchConfirmation(context, b);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

  void _showSwitchConfirmation(BuildContext context, dynamic targetBusiness) {
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
                AppFeedback.showSuccess(
                  context,
                  'Switched to ${targetBusiness.name}',
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

  void _showQuickMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final authState = ref.watch(authProvider);
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  if (authState.hasPermission(
                    PermissionModule.inventory,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/stock-management');
                      },
                    ),
                  if (authState.hasPermission(
                    PermissionModule.billing,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.receipt_long,
                      label: 'Invoices',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/invoice-history');
                      },
                    ),
                  if (authState.hasPermission(
                    PermissionModule.products,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.add_circle_outline,
                      label: 'Products',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/products');
                      },
                    ),
                  if (ref.watch(featureSettingsProvider).isCategoryEnabled &&
                      authState.hasPermission(
                        PermissionModule.categories,
                        PermissionAction.view,
                      ))
                    _QuickMenuItem(
                      icon: Icons.category_outlined,
                      label: 'Categories',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryManagementPage(),
                          ),
                        );
                      },
                    ),
                  if (authState.hasPermission(
                    PermissionModule.userManagement,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Staff',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/user-management');
                      },
                    ),
                  if (authState.hasPermission(
                    PermissionModule.uom,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.straighten,
                      label: 'UOM',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UomManagementPage(),
                          ),
                        );
                      },
                    ),
                  if (authState.hasPermission(
                    PermissionModule.customers,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.people_alt_outlined,
                      label: 'Customers',
                      color: Colors.pink,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/customers');
                      },
                    ),
                  if (authState.hasPermission(
                    PermissionModule.payments,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Khata',
                      color: Colors.cyan,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KhataDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  if (authState.hasPermission(
                    PermissionModule.analytics,
                    PermissionAction.view,
                  ))
                    _QuickMenuItem(
                      icon: Icons.analytics,
                      label: 'Reports',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AnalyticsDashboardScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final dynamic business;
  final dynamic user;
  final VoidCallback onTap;

  const _HomeHeader({
    required this.business,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // User Profile Photo on the Left - Full View
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageViewer(
                    imagePath: user?.photo,
                    tag: 'profile_photo_dashboard',
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'profile_photo_dashboard',
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryTeal.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    if (user?.photo == null || user!.photo!.isEmpty) {
                      return const Icon(Icons.person, color: AppTheme.primaryTeal, size: 30);
                    }

                    try {
                      final photo = user!.photo!;
                      if (photo.startsWith('http')) {
                        return CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                          backgroundImage: NetworkImage(photo),
                          onBackgroundImageError: (_, __) {},
                        );
                      }

                      final bytes = ImageUtils.decodeBase64(photo);
                      if (bytes.isNotEmpty) {
                        return CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                          backgroundImage: MemoryImage(bytes),
                          onBackgroundImageError: (_, __) {},
                        );
                      }

                      // Fallback for local files
                      if (File(photo).existsSync()) {
                        return CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                          backgroundImage: FileImage(File(photo)),
                          onBackgroundImageError: (_, __) {},
                        );
                      }
                    } catch (e) {
                      debugPrint('Error decoding image: $e');
                    }
                    
                    return const Icon(Icons.person, color: AppTheme.primaryTeal, size: 30);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.name ?? 'User'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
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
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Business Logo on the Right - Current behavior (switch business)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: business?.business_logo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        ImageUtils.decodeBase64(business!.business_logo!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.business_rounded,
                      color: AppTheme.primaryTeal,
                      size: 28,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryTeal : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryTeal : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _ModuleCard extends StatelessWidget {
  final _ModuleItem item;

  const _ModuleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
