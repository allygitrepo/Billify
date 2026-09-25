import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/presentation/widgets/app_crash_fallback_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Production Readiness & Error Boundary Tests', () {
    testWidgets('AppCrashFallbackView renders graceful recovery UI without crashing', (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('Simulated widget rendering failure'),
        stack: StackTrace.current,
      );

      await tester.pumpWidget(
        AppCrashFallbackView(errorDetails: details),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    test('AppTheme light and dark theme configurations are production ready', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.brightness, equals(Brightness.light));
      expect(dark.brightness, equals(Brightness.dark));
      expect(light.primaryColor, equals(AppTheme.primaryTeal));
      expect(dark.primaryColor, equals(AppTheme.primaryTeal));
    });
  });
}
