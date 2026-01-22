import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/core/utils/arabic_helper.dart';

void main() {
  group('ArabicHelper Tests', () {
    test('reshapedText should handle empty string', () {
      expect(ArabicHelper.reshapedText(''), '');
    });

    test('reshapedText should handle Arabic text correctly', () {
      const input = 'كشف حساب';
      final result = ArabicHelper.reshapedText(input);

      // The result should be the same as input since we're using font-based rendering
      expect(result, equals(input));
      expect(result, isNotEmpty);
    });

    test('reshapedText should handle mixed Arabic and numbers', () {
      const input = 'الفاتورة رقم 123';
      final result = ArabicHelper.reshapedText(input);

      expect(result, equals(input));
      expect(result, isNotEmpty);
      expect(result, contains('123'));
    });

    test('reshapedText should handle Arabic with separators', () {
      const input = '2023/12/01';
      final result = ArabicHelper.reshapedText(input);

      // Numbers and separators should remain unchanged
      expect(result, equals(input));
      expect(result, contains('2023'));
      expect(result, contains('/'));
      expect(result, contains('12'));
      expect(result, contains('01'));
    });

    test('reshapedText should handle customer name', () {
      const input = 'أحمد محمد علي';
      final result = ArabicHelper.reshapedText(input);

      expect(result, equals(input));
      expect(result, isNotEmpty);
    });

    test('reshapedText should handle product descriptions', () {
      const input = 'كمية 10 قطعة بسعر 15.50 ج.م';
      final result = ArabicHelper.reshapedText(input);

      expect(result, equals(input));
      expect(result, contains('10'));
      expect(result, contains('15.50'));
      expect(result, contains('ج.م'));
    });

    test('reshapedText should handle single Arabic word', () {
      const input = 'الإجمالي';
      final result = ArabicHelper.reshapedText(input);

      expect(result, equals(input));
      expect(result, isNotEmpty);
    });

    test('reshapedText should handle Arabic with English letters', () {
      const input = 'المبلغ USD 100.50';
      final result = ArabicHelper.reshapedText(input);

      expect(result, equals(input));
      expect(result, contains('USD'));
      expect(result, contains('100.50'));
    });

    test('reshapedText should handle long Arabic sentences', () {
      const input =
          'هذا نص تجريبي طويل لاختبار أداء مكتبة إعادة تشكيل النصوص العربية في ملفات PDF';
      final result = ArabicHelper.reshapedText(input);

      expect(result, equals(input));
      expect(result, isNotEmpty);
    });

    test('reshapedText should handle special Arabic characters', () {
      const input = 'آية مؤمنة أحمد';
      final result = ArabicHelper.reshapedText(input);

      expect(result, equals(input));
      expect(result, isNotEmpty);
    });
  });
}
