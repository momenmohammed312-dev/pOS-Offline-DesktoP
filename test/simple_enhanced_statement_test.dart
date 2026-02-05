import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/core/utils/currency_helper.dart';

void main() {
  group('Simple Enhanced Statement Tests', () {
    test('يجب تنسيق مبلغ بسيط', () {
      final result = CurrencyHelper.formatCurrency(123.45);
      expect(result, '123.45 ج.م');
    });

    test('يجب تنسيق مبلغ سالب', () {
      final result = CurrencyHelper.formatCurrency(-123.45);
      expect(result, '-123.45 ج.م');
    });

    test('يجب تنسيق مبلغ كبير', () {
      final result = CurrencyHelper.formatCurrency(1234567.89);
      expect(result, '1,234,567.89 ج.م');
    });
  });
}
