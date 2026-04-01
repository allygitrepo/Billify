import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/presentation/auth/login_page.dart';
import 'package:billify_application/presentation/auth/register_page.dart';
import 'package:billify_application/presentation/business/business_setup_page.dart';
import 'package:billify_application/presentation/home/home_page.dart';
import 'package:billify_application/presentation/billing/invoice_history_page.dart';
import 'package:billify_application/presentation/billing/scanner_screen.dart';
import 'package:billify_application/presentation/inventory/stock_management_page.dart';
import 'package:billify_application/presentation/product/product_management_page.dart';
import 'package:billify_application/presentation/splash/splash_page.dart';
import 'package:billify_application/presentation/settings/user_management_page.dart';
import 'package:billify_application/presentation/settings/profile_page.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:billify_application/providers/theme_provider.dart';
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
        '/add-product': (context) => const ProductManagementPage(), // Alias for compatibility
        '/invoice-history': (context) => const InvoiceHistoryPage(),
        '/stock-management': (context) => const StockManagementPage(),
        '/user-management': (context) => const UserManagementPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
