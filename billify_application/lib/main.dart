import 'dart:ui';
import 'package:billify/core/routes/app_router.dart';
import 'package:billify/core/routes/app_routes.dart';
import 'package:billify/core/services/ad_service.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_logger.dart';
import 'package:billify/presentation/widgets/app_crash_fallback_view.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:billify/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Global Framework Error Interceptor
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter framework error caught',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'GlobalCrashHandler',
    );
  };

  // 2. Platform & Asynchronous Uncaught Error Interceptor
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error(
      'Asynchronous root error caught',
      error: error,
      stackTrace: stack,
      tag: 'GlobalCrashHandler',
    );
    return true; // Mark as handled to prevent process termination
  };

  // 3. Graceful UI Error Boundary
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppCrashFallbackView(errorDetails: details);
  };

  // 4. Initialize Local Storage
  final prefs = await SharedPreferences.getInstance();

  // 5. Initialize Google Mobile Ads asynchronously
  AdService.instance.initialize();

  AppLogger.info('Billify POS initialized successfully', tag: 'Bootstrap');

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
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
