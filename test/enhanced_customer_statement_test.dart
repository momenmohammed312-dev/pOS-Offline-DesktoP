import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/core/utils/currency_helper.dart';

void main() {
  group('Enhanced Customer Statement - Currency Formatting', () {
    test('يجب تنسيق المبلغ الموجب بشكل صحيح', () {
      final result = CurrencyHelper.formatCurrency(123.45);
      expect(result, '123.45 ج.م');
    });

    test('يجب معالجة القيمة null', () {
      final result = CurrencyHelper.formatCurrency(null);
      expect(result, '0.00 ج.م');
    });

    test('يجب معالجة NaN', () {
      final result = CurrencyHelper.formatCurrency(double.nan);
      expect(result, '0.00 ج.م');
    });

    test('يجب معالجة Infinity', () {
      final result = CurrencyHelper.formatCurrency(double.infinity);
      expect(result, '0.00 ج.م');
    });

    test('يجب تنسيق المبلغ السالب', () {
      final result = CurrencyHelper.formatCurrency(-123.45);
      expect(result, '-123.45 ج.م');
    });

    test('يجب تنسيق الصفر', () {
      final result = CurrencyHelper.formatCurrency(0);
      expect(result, '0.00 ج.م');
    });

    test('يجب تنسيق المبلغ الكبير بفواصل', () {
      final result = CurrencyHelper.formatCurrency(1234567.89);
      expect(result, '1,234,567.89 ج.م');
    });

    test('يجب تحويل String إلى مبلغ', () {
      final result = CurrencyHelper.formatCurrency('123.45');
      expect(result, '123.45 ج.م');
    });

    test('يجب معالجة String غير صحيح', () {
      final result = CurrencyHelper.formatCurrency('abc');
      expect(result, '0.00 ج.م');
    });

    test('يجب التنسيق بدون رمز العملة', () {
      final result = CurrencyHelper.formatCurrency(123.45, showSymbol: false);
      expect(result, '123.45');
    });
  });

  group('Enhanced Customer Statement - Parsing', () {
    test('يجب استخراج الرقم من النص المنسق', () {
      final amount = CurrencyHelper.parseFormattedCurrency('123.45 ج.م');
      expect(amount, 123.45);
    });

    test('يجب استخراج الرقم مع فواصل', () {
      final amount = CurrencyHelper.parseFormattedCurrency('1,234,567.89 ج.م');
      expect(amount, 1234567.89);
    });

    test('يجب معالجة نص فارغ', () {
      final amount = CurrencyHelper.parseFormattedCurrency('');
      expect(amount, 0.0);
    });
  });

  group('Enhanced Customer Statement - Safe Conversions', () {
    test('يجب تحويل int إلى double', () {
      final result = CurrencyHelper.toDouble(123);
      expect(result, 123.0);
    });

    test('يجب تحويل String إلى double', () {
      final result = CurrencyHelper.toDouble('123.45');
      expect(result, 123.45);
    });

    test('يجب معالجة NaN في التحويل', () {
      final result = CurrencyHelper.toDouble(double.nan);
      expect(result, 0.0);
    });

    test('يجب تقريب الأرقام', () {
      final result = CurrencyHelper.round(123.456789);
      expect(result, 123.46);
    });
  });
}
