import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/ui/customer/services/enhanced_customer_statement_generator.dart';

void main() {
  group('EnhancedCustomerStatementGenerator Simple Tests', () {
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

    test('should handle negative values', () {
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(-123.45),
        equals('-123.45 ج.م'),
      );
    });

    test('should handle large values', () {
      expect(
        EnhancedCustomerStatementGenerator.formatCurrency(1234567.89),
        equals('1,234,567.89 ج.م'),
      );
    });
  });
}
