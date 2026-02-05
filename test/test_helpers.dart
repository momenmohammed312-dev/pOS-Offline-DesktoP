import 'package:flutter_test/flutter_test.dart';

class TestHelpers {
  /// مقارنة آمنة للنصوص العربية
  static void expectArabicText(String actual, String expected) {
    // تطبيع النصوص قبل المقارنة
    final normalizedActual = _normalizeArabic(actual);
    final normalizedExpected = _normalizeArabic(expected);

    expect(normalizedActual, normalizedExpected);
  }

  static String _normalizeArabic(String text) {
    // إزالة المسافات الزائدة
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    // توحيد الهمزات
    text = text.replaceAll(RegExp(r'[أإآا]'), 'ا');

    // توحيد الياء
    text = text.replaceAll(RegExp(r'[يى]'), 'ي');

    return text;
  }

  /// مقارنة آمنة للأرقام
  static void expectCurrency(String actual, double expectedAmount) {
    // التعامل مع حالة NaN
    if (actual.contains('NaN') || actual.contains('ليس رقماً')) {
      expect(expectedAmount, closeTo(0.0, 0.01));
      return;
    }

    // استخراج الرقم من النص مع دعم الأرقام العربية والسالب
    final numberPattern = RegExp(r'-?[٠-٩\d]+[.,]?[٠-٩\d]*');
    final match = numberPattern.firstMatch(actual);

    if (match != null) {
      var numberStr = match.group(0)!;

      // تحويل الأرقام العربية إلى أرقام إنجليزية
      numberStr = _convertArabicNumbersToEnglish(numberStr);

      // إزالة الفواصل
      numberStr = numberStr.replaceAll(',', '').replaceAll('٬', '');

      final actualAmount = double.tryParse(numberStr) ?? 0.0;

      expect(actualAmount, closeTo(expectedAmount, 0.01));
    } else {
      fail('لم يتم العثور على رقم في: $actual');
    }
  }

  /// تحويل الأرقام العربية إلى أرقام إنجليزية
  static String _convertArabicNumbersToEnglish(String text) {
    const arabicNumbers = '٠١٢٣٤٥٦٧٨٩';
    const englishNumbers = '0123456789';

    for (int i = 0; i < arabicNumbers.length; i++) {
      text = text.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }

    return text;
  }

  /// wrapper للاختبارات مع timeout
  static void testWithTimeout(
    String description,
    dynamic Function() body, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    test(description, body, timeout: Timeout(timeout));
  }
}
