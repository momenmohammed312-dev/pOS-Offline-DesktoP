import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/ui/customer/services/enhanced_customer_statement_generator.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('EnhancedCustomerStatementGenerator Tests', () {
    late AppDatabase db;

    setUp(() {
      // Use in-memory database for testing
      db = AppDatabase(drift.DatabaseConnection(NativeDatabase.memory()));
    });

    tearDown(() async {
      await db.close();
    });

    test('should format currency correctly', () {
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(123.45),
        equals('123.45 ج.م'),
      );
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(0.0),
        equals('0.00 ج.م'),
      );
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(double.nan),
        equals('0.00 ج.م'),
      );
    });

    test('should handle NaN values in currency formatting', () {
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(double.nan),
        equals('0.00 ج.م'),
      );
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(double.infinity),
        equals('∞ ج.م'),
      );
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(
          double.negativeInfinity,
        ),
        equals('-∞ ج.م'),
      );
    });

    group('Edge Cases', () {
      test('should handle NaN values in currency formatting', () {
        expect(
          EnhancedCustomerStatementGenerator.formatCurrency(double.nan),
          equals('0.00 ج.م'),
        );
        expect(
          EnhancedCustomerStatementGenerator.formatCurrency(double.infinity),
          equals('∞ ج.م'),
        );
        expect(
          EnhancedCustomerStatementGenerator.formatCurrency(
            double.negativeInfinity,
          ),
          equals('-∞ ج.م'),
        );
      });

      test('should handle negative balances', () {
        expect(
          EnhancedCustomerStatementGenerator.formatCurrency(-123.45),
          equals('-123.45 ج.م'),
        );
      });

      test('should handle zero values', () {
        expect(
          EnhancedCustomerStatementGenerator.formatCurrency(0.0),
          equals('0.00 ج.م'),
        );
      });
    });

    group('Integration Tests', () {
      test('should handle database connection for testing', () {
        expect(db, isNotNull);
        expect(db, isA<AppDatabase>());
      });

      test('should be able to access database methods', () {
        expect(db.customerDao, isNotNull);
        expect(db.invoiceDao, isNotNull);
        expect(db.ledgerDao, isNotNull);
      });
    });
  });
}
