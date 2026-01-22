import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/core/utils/arabic_helper.dart';

bool containsArabic(String text) {
  return text.codeUnits.any(
    (codeUnit) => codeUnit >= 0x0600 && codeUnit <= 0x06FF,
  );
}

void main() {
  group('Arabic PDF Integration Tests', () {
    test('ArabicHelper processes common PDF text elements', () {
      // Test common Arabic text used in PDFs
      const testTexts = [
        'كشف حساب',
        'الاسم',
        'التاريخ',
        'المبلغ',
        'الرصيد',
        'مدين',
        'دائن',
        'الإجمالي',
        'الخصم',
        'المتبقي',
        'الفاتورة',
        'عميل',
        'مورد',
        'منتج',
        'الكمية',
        'السعر',
        'الوحدة',
        'ملاحظات',
        'البيان',
        'الرقم',
        'صفحة',
        'تم الاستخراج في',
      ];

      for (final text in testTexts) {
        final result = ArabicHelper.reshapedText(text);
        expect(result, isNotEmpty, reason: 'Text should not be empty: $text');
        // Arabic text gets reshaped, so we check that it's processed (different from input)
        expect(
          result,
          isA<String>(),
          reason: 'Result should be a string: $text',
        );
        // For Arabic text, the reshaped version should be different from input
        if (containsArabic(text)) {
          expect(
            result,
            isNot(equals(text)),
            reason: 'Arabic text should be reshaped: $text',
          );
        }
      }
    });

    test('ArabicHelper handles mixed content correctly', () {
      const mixedTexts = [
        'الفاتورة رقم 123',
        'المبلغ: 150.75 ج.م',
        '2023/12/01',
        'كمية 10 قطعة',
        'السعر USD 50.00',
        'رصيد سابق: 1000.00',
        'الخصم 10%',
        'صفحة 1/5',
        'تم في 2023/12/01 10:30',
      ];

      for (final text in mixedTexts) {
        final result = ArabicHelper.reshapedText(text);
        expect(
          result,
          isNotEmpty,
          reason: 'Mixed text should not be empty: $text',
        );
        expect(
          result,
          isA<String>(),
          reason: 'Mixed text should be a string: $text',
        );
        // For text containing Arabic, the reshaped version should be different
        if (containsArabic(text)) {
          expect(
            result,
            isNot(equals(text)),
            reason: 'Mixed text with Arabic should be reshaped: $text',
          );
        }
      }
    });

    test('ArabicHelper handles edge cases', () {
      final edgeCases = [
        '', // Empty string
        ' ', // Single space
        '123', // Numbers only
        'ABC', // English only
        '!@#\$%^&*()', // Special characters
        'أ', // Single Arabic letter
        'أبجد', // Arabic letters only
        'أ 1 ب 2 ج', // Mixed with spaces
      ];

      for (final text in edgeCases) {
        final result = ArabicHelper.reshapedText(text);
        expect(
          result,
          isA<String>(),
          reason: 'Edge case should return a string: "$text"',
        );
        // For non-Arabic text, should remain the same
        if (!containsArabic(text) || text.isEmpty) {
          expect(
            result,
            equals(text),
            reason: 'Non-Arabic text should be preserved: "$text"',
          );
        } else {
          // Arabic text should be reshaped (different from input)
          expect(
            result,
            isNot(equals(text)),
            reason: 'Arabic text should be reshaped: "$text"',
          );
        }
      }
    });

    test('ArabicHelper maintains consistency across calls', () {
      final text = 'كشف حساب العميل';

      final result1 = ArabicHelper.reshapedText(text);
      final result2 = ArabicHelper.reshapedText(text);
      final result3 = ArabicHelper.reshapedText(text);

      expect(result1, equals(result2));
      expect(result2, equals(result3));
      // All results should be the same reshaped text, different from original
      expect(result1, isNot(equals(text)));
      expect(result2, isNot(equals(text)));
      expect(result3, isNot(equals(text)));
    });
  });
}
