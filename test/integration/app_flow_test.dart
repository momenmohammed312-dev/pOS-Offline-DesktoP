import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/main.dart';
import 'package:drift/native.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/provider/app_database_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setupMockData(AppDatabase db) async {
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            name: 'Test Product',
            price: 10.0,
            quantity: 100,
          ),
        );
    await db.dayDao.openDay(openingBalance: 100.0);
  }

  group('App Flow Integration Test', () {
    testWidgets('Full User Flow: Products -> Dashboard -> New Invoice', (
      WidgetTester tester,
    ) async {
      await setupMockData(db);

      // 1. Initial Launch
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Navigate to Products Tab
      // Find Tab with text 'المنتجات' (Products in Arabic)
      final productsTab = find.descendant(
        of: find.byType(Tab),
        matching: find.text('المنتجات'),
      );
      await tester.tap(productsTab);
      await tester.pumpAndSettle();

      // Verify we are on Products screen (looking for add product button)
      expect(find.text('إضافة منتج'), findsOneWidget);

      // 3. Navigate back to Dashboard Tab
      final dashboardTab = find.descendant(
        of: find.byType(Tab),
        matching: find.text('لوحة التحكم'),
      );
      await tester.tap(dashboardTab);
      await tester.pumpAndSettle();

      // 4. Start New Invoice from Dashboard
      await tester.tap(find.byIcon(Icons.receipt_long));
      await tester.pumpAndSettle();

      // Handle Invoice Type Modal (using Arabic text from the widget)
      expect(find.text('اختر نوع الفاتورة'), findsOneWidget);
      await tester.tap(find.text('نقدي'));
      await tester.pumpAndSettle();

      // Verify New Invoice Page open - looking for search hint
      expect(find.text('البحث عن المنتجات...'), findsOneWidget);

      // 5. Add a product to cart
      // The ProductCard displays product.name
      await tester.tap(find.text('Test Product'));
      await tester.pumpAndSettle();

      // Handling ProductSelectionModal
      expect(find.text('Add to Invoice'), findsOneWidget);
      await tester.tap(find.text('Add to Invoice'));
      await tester.pumpAndSettle();

      // Check if item added (looking for price text in OrderLineItem)
      expect(find.textContaining('10.00'), findsAtLeastNWidgets(1));

      // 6. Complete Invoice
      // The button text in EnhancedNewInvoicePage is 'إكمال والطباعة'
      await tester.tap(find.text('إكمال والطباعة'));
      await tester.pumpAndSettle();

      // Should return to Dashboard
      expect(find.text('لوحة التحكم'), findsOneWidget);
    });
  });
}
