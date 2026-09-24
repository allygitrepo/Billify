import 'package:billify/presentation/widgets/app_confirmation_dialog.dart';
import 'package:billify/presentation/widgets/app_search_bar.dart';
import 'package:billify/presentation/widgets/app_stat_card.dart';
import 'package:billify/presentation/widgets/app_shimmer.dart';
import 'package:billify/presentation/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reusability & UI Design System Widget Tests', () {
    testWidgets('AppConfirmationDialog displays title, message, and returns true on confirm', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await AppConfirmationDialog.showDelete(
                    context,
                    itemName: 'Test Item',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is rendered
      expect(find.text('Delete Test Item?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });

    testWidgets('AppSearchBar debounces query typing and supports clear', (tester) async {
      String lastQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              hintText: 'Search products...',
              debounceDuration: const Duration(milliseconds: 100),
              onChanged: (q) => lastQuery = q,
            ),
          ),
        ),
      );

      expect(find.text('Search products...'), findsOneWidget);

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.pump();

      // Before debounce fires
      expect(lastQuery, equals(''));

      // Settle timer
      await tester.pumpAndSettle(const Duration(milliseconds: 150));
      expect(lastQuery, equals('Milk'));

      // Clear button should be visible now
      expect(find.byIcon(Icons.clear), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(lastQuery, equals(''));
    });

    testWidgets('AppStatCard displays metrics, trends, and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppStatCard(
              title: 'Total Revenue',
              value: '₹ 45,200',
              subtitle: 'vs last month',
              icon: Icons.currency_rupee,
              trendText: '+12.5%',
              isTrendPositive: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('₹ 45,200'), findsOneWidget);
      expect(find.text('+12.5%'), findsOneWidget);
      expect(find.text('vs last month'), findsOneWidget);

      await tester.tap(find.byType(AppStatCard));
      expect(tapped, isTrue);
    });

    testWidgets('AppShimmer renders placeholder box without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppShimmer.box(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(AppShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('AppBottomSheet renders title, grab handle, and custom children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomSheet(
              title: 'Edit Customer',
              child: const Text('Customer Form Body'),
            ),
          ),
        ),
      );

      expect(find.text('Edit Customer'), findsOneWidget);
      expect(find.text('Customer Form Body'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
