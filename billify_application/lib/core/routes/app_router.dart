import 'package:billify/core/routes/app_routes.dart';
import 'package:billify/core/routes/route_arguments.dart';
import 'package:billify/features/analytics/customer_reports/presentation/customer_reports_screen.dart';
import 'package:billify/features/analytics/khata_reports/presentation/khata_reports_screen.dart';
import 'package:billify/features/analytics/profit_reports/presentation/profit_reports_screen.dart';
import 'package:billify/features/analytics/sales_reports/presentation/sales_reports_screen.dart';
import 'package:billify/presentation/analytics/analytics_dashboard_screen.dart';
import 'package:billify/presentation/analytics/report_screens.dart';
import 'package:billify/presentation/auth/login_page.dart';
import 'package:billify/presentation/auth/register_page.dart';
import 'package:billify/presentation/billing/invoice_history_page.dart';
import 'package:billify/presentation/billing/scanner_screen.dart';
import 'package:billify/presentation/business/business_setup_page.dart';
import 'package:billify/presentation/customers/business_customers_import_screen.dart';
import 'package:billify/presentation/customers/contacts_import_screen.dart';
import 'package:billify/presentation/customers/customer_detail_screen.dart';
import 'package:billify/presentation/customers/customer_list_screen.dart';
import 'package:billify/presentation/home/home_page.dart';
import 'package:billify/presentation/inventory/stock_management_page.dart';
import 'package:billify/presentation/payments/add_payment_screen.dart';
import 'package:billify/presentation/product/product_management_page.dart';
import 'package:billify/presentation/settings/category_management_page.dart';
import 'package:billify/presentation/settings/profile_page.dart';
import 'package:billify/presentation/settings/uom_management_page.dart';
import 'package:billify/presentation/settings/user_management_page.dart';
import 'package:billify/presentation/splash/splash_page.dart';
import 'package:billify/presentation/widgets/error_retry_view.dart';
import 'package:flutter/material.dart';

/// Central Route Generator decoupling navigation from main.dart
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashPage(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.register:
        return _buildRoute(const RegisterPage(), settings);

      case AppRoutes.businessSetup:
        return _buildRoute(const BusinessSetupPage(), settings);

      case AppRoutes.home:
        return _buildRoute(const HomePage(), settings);

      case AppRoutes.scanner:
        return _buildRoute(const ScannerScreen(), settings);

      case AppRoutes.products:
      case AppRoutes.addProduct:
        String? barcode;
        if (settings.arguments is String) {
          barcode = settings.arguments as String;
        } else if (settings.arguments is ProductRouteArgs) {
          barcode = (settings.arguments as ProductRouteArgs).initialBarcode;
        }
        return _buildRoute(
          ProductManagementPage(initialBarcode: barcode),
          settings,
        );

      case AppRoutes.invoiceHistory:
        return _buildRoute(const InvoiceHistoryPage(), settings);

      case AppRoutes.stockManagement:
        return _buildRoute(const StockManagementPage(), settings);

      case AppRoutes.userManagement:
        return _buildRoute(const UserManagementPage(), settings);

      case AppRoutes.profile:
        return _buildRoute(const ProfilePage(), settings);

      case AppRoutes.customers:
        return _buildRoute(const CustomerListScreen(), settings);

      case AppRoutes.customerDetail:
        int? customerId;
        if (settings.arguments is CustomerDetailRouteArgs) {
          customerId = (settings.arguments as CustomerDetailRouteArgs).customerId;
        } else if (settings.arguments is Map && (settings.arguments as Map).containsKey('customerId')) {
          customerId = (settings.arguments as Map)['customerId'] as int?;
        } else if (settings.arguments is int) {
          customerId = settings.arguments as int;
        }

        if (customerId != null) {
          return _buildRoute(CustomerDetailScreen(customerId: customerId), settings);
        }
        return _buildRoute(
          const Scaffold(
            body: Center(
              child: ErrorRetryView(
                title: 'Invalid Navigation',
                message: 'A valid customer ID is required to view details.',
              ),
            ),
          ),
          settings,
        );

      case AppRoutes.contactsImport:
        return _buildRoute(const ContactsImportScreen(), settings);

      case AppRoutes.businessCustomersImport:
        return _buildRoute(const BusinessCustomersImportScreen(), settings);

      case AppRoutes.categoryManagement:
        return _buildRoute(const CategoryManagementPage(), settings);

      case AppRoutes.uomManagement:
        return _buildRoute(const UomManagementPage(), settings);

      case AppRoutes.addPayment:
        int? customerId;
        if (settings.arguments is AddPaymentRouteArgs) {
          customerId = (settings.arguments as AddPaymentRouteArgs).customerId;
        } else if (settings.arguments is Map && (settings.arguments as Map).containsKey('customerId')) {
          customerId = (settings.arguments as Map)['customerId'] as int?;
        } else if (settings.arguments is int) {
          customerId = settings.arguments as int;
        }

        if (customerId != null) {
          return _buildRoute(AddPaymentScreen(customerId: customerId), settings);
        }
        return _buildRoute(
          const Scaffold(
            body: Center(
              child: ErrorRetryView(
                title: 'Invalid Navigation',
                message: 'A valid customer ID is required to record payment.',
              ),
            ),
          ),
          settings,
        );

      case AppRoutes.analytics:
        return _buildRoute(const AnalyticsDashboardScreen(), settings);

      case AppRoutes.analyticsSales:
        return _buildRoute(const SalesReportsScreen(), settings);

      case AppRoutes.analyticsProfit:
        return _buildRoute(const ProfitReportsScreen(), settings);

      case AppRoutes.analyticsInventory:
        return _buildRoute(const InventoryReportsScreen(), settings);

      case AppRoutes.analyticsCustomers:
        return _buildRoute(const CustomerReportsScreen(), settings);

      case AppRoutes.analyticsKhata:
        return _buildRoute(const KhataReportsScreen(), settings);

      case AppRoutes.analyticsPayments:
        return _buildRoute(const PaymentReportsScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: ErrorRetryView(
                title: '404 - Page Not Found',
                message: 'The route "${settings.name}" does not exist.',
              ),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => page,
      settings: settings,
    );
  }
}
