import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/core/utils/text_utils.dart';
import 'test_helpers.dart';

void main() {
  group('Arabic Text Processing', () {
    TestHelpers.testWithTimeout('يجب معالجة النص العربي البسيط', () {
      final input = 'كشف حساب';
      final result = TextUtils.processArabicText(input);

      // استخدام المقارنة الآمنة
      TestHelpers.expectArabicText(result, 'كشف حساب');
    });

    TestHelpers.testWithTimeout('يجب معالجة النص المختلط', () {
      final input = 'الفاتورة رقم 123';
      final result = TextUtils.processArabicText(input);

      expect(result, contains('123'));
      TestHelpers.expectArabicText(result, 'الفاتورة رقم 123');
    });

    TestHelpers.testWithTimeout('يجب معالجة الأسماء', () {
      final input = 'أحمد محمد علي';
      final result = TextUtils.processArabicText(input);

      TestHelpers.expectArabicText(result, 'أحمد محمد علي');
    });

    TestHelpers.testWithTimeout('يجب معالجة النصوص الطويلة', () {
      final input = 'هذا نص تجريبي طويل لاختبار أداء معالجة النصوص العربية';
      final result = TextUtils.processArabicText(input);

      expect(result, isNotEmpty);
      expect(result, contains('تجريبي'));
    });

    TestHelpers.testWithTimeout('يجب معالجة الأحرف الخاصة', () {
      final input = 'آية مؤمنة أحمد';
      final result = TextUtils.processArabicText(input);

      expect(result, isNotEmpty);
      expect(result, contains('آية'));
    });
  });

  group('Currency Formatting', () {
    TestHelpers.testWithTimeout('يجب تنسيق المبلغ الموجب', () {
      final result = TextUtils.formatCurrency(123.45);
      TestHelpers.expectCurrency(result, 123.45);
      expect(result, contains('ج.م'));
    });

    TestHelpers.testWithTimeout('يجب معالجة NaN', () {
      final result = TextUtils.formatCurrency(double.nan);
      TestHelpers.expectCurrency(result, 0.0);
    });

    TestHelpers.testWithTimeout('يجب تنسيق الأرقام الكبيرة', () {
      final result = TextUtils.formatCurrency(1234567.89);
      expect(result, contains('1,234,567.89'));
    });

    TestHelpers.testWithTimeout('يجب تنسيق الصفر', () {
      final result = TextUtils.formatCurrency(0.0);
      TestHelpers.expectCurrency(result, 0.0);
    });

    TestHelpers.testWithTimeout('يجب تنسيق الأرقام السالبة', () {
      final result = TextUtils.formatCurrency(-123.45);
      TestHelpers.expectCurrency(result, -123.45);
    });
  });

  group('Number Formatting', () {
    TestHelpers.testWithTimeout('يجب تنسيق الأرقام العشرية', () {
      final result = TextUtils.formatNumber(123.4567);
      expect(result, equals('123.46'));
    });

    TestHelpers.testWithTimeout('يجب تنسيق مع فواصل الآلاف', () {
      final result = TextUtils.formatWithSeparators(1234567.89);
      expect(result, contains('1,234,567.89'));
    });

    TestHelpers.testWithTimeout('يجب معالجة null', () {
      final result = TextUtils.formatNumber(null);
      expect(result, equals('0.00'));
    });
  });
}
