import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/presentation/auth/login_page.dart';
import 'package:billify/presentation/auth/register_page.dart';
import 'package:billify/presentation/business/business_setup_page.dart';
import 'package:billify/presentation/home/home_page.dart';
import 'package:billify/presentation/billing/invoice_history_page.dart';
import 'package:billify/presentation/billing/scanner_screen.dart';
import 'package:billify/presentation/inventory/stock_management_page.dart';
import 'package:billify/presentation/product/product_management_page.dart';
import 'package:billify/presentation/splash/splash_page.dart';
import 'package:billify/presentation/settings/user_management_page.dart';
import 'package:billify/presentation/settings/profile_page.dart';
import 'package:billify/presentation/customers/customer_list_screen.dart';
import 'package:billify/presentation/payments/add_payment_screen.dart';
import 'package:billify/presentation/analytics/analytics_dashboard_screen.dart';
import 'package:billify/presentation/analytics/report_screens.dart';
import 'package:billify/features/analytics/sales_reports/presentation/sales_reports_screen.dart';
import 'package:billify/features/analytics/profit_reports/presentation/profit_reports_screen.dart';
import 'package:billify/features/analytics/khata_reports/presentation/khata_reports_screen.dart';
import 'package:billify/features/analytics/customer_reports/presentation/customer_reports_screen.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:billify/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BillifyApp(),
    ),
  );
}

class BillifyApp extends ConsumerWidget {
  const BillifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Billify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/business-setup': (context) => const BusinessSetupPage(),
        '/home': (context) => const HomePage(),
        '/scanner': (context) => const ScannerScreen(),
        '/products': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return ProductManagementPage(initialBarcode: args);
          }
          return const ProductManagementPage();
        },
        '/add-product': (context) =>
            const ProductManagementPage(), // Alias for compatibility
        '/invoice-history': (context) => const InvoiceHistoryPage(),
        '/stock-management': (context) => const StockManagementPage(),
        '/user-management': (context) => const UserManagementPage(),
        '/profile': (context) => const ProfilePage(),
        '/customers': (context) => const CustomerListScreen(),
        '/add-payment': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          if (args != null && args.containsKey('customerId')) {
            return AddPaymentScreen(customerId: args['customerId'] as int);
          }
          return const Scaffold(
            body: Center(child: Text('CustomerId required')),
          );
        },
        '/analytics': (context) => const AnalyticsDashboardScreen(),
        '/analytics/sales': (context) => const SalesReportsScreen(),
        '/analytics/profit': (context) => const ProfitReportsScreen(),
        '/analytics/inventory': (context) => const InventoryReportsScreen(),
        '/analytics/customers': (context) => const CustomerReportsScreen(),
        '/analytics/khata': (context) => const KhataReportsScreen(),
        '/analytics/payments': (context) => const PaymentReportsScreen(),
      },
    );
  }
}
