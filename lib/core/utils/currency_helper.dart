import 'package:intl/intl.dart';

class CurrencyHelper {
  // منع إنشاء instances
  CurrencyHelper._();

  /// رمز العملة المصرية
  static const String egpSymbol = 'ج.م';

  /// تنسيق المبلغ بالجنيه المصري
  static String formatCurrency(dynamic amount, {bool showSymbol = true}) {
    // معالجة الحالات الخاصة
    if (amount == null) return showSymbol ? '0.00 $egpSymbol' : '0.00';

    double numAmount;

    if (amount is String) {
      numAmount = double.tryParse(amount) ?? 0.0;
    } else if (amount is int) {
      numAmount = amount.toDouble();
    } else if (amount is double) {
      numAmount = amount;
    } else {
      numAmount = 0.0;
    }

    // معالجة NaN و Infinity
    if (numAmount.isNaN || numAmount.isInfinite) {
      numAmount = 0.0;
    }

    // تنسيق الرقم مع فواصل الآلاف باستخدام اللغة الإنجليزية للأرقام
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formatted = formatter.format(numAmount);

    return showSymbol ? '$formatted $egpSymbol' : formatted;
  }

  /// تنسيق بدون فواصل الآلاف
  static String formatCurrencySimple(dynamic amount, {bool showSymbol = true}) {
    // معالجة الحالات الخاصة
    if (amount == null) return showSymbol ? '0.00 $egpSymbol' : '0.00';

    double numAmount;

    if (amount is String) {
      numAmount = double.tryParse(amount) ?? 0.0;
    } else if (amount is int) {
      numAmount = amount.toDouble();
    } else if (amount is double) {
      numAmount = amount;
    } else {
      numAmount = 0.0;
    }

    // معالجة NaN و Infinity
    if (numAmount.isNaN || numAmount.isInfinite) {
      numAmount = 0.0;
    }

    final formatted = numAmount.toStringAsFixed(2);

    return showSymbol ? '$formatted $egpSymbol' : formatted;
  }

  /// استخراج الرقم من نص منسق
  static double parseFormattedCurrency(String formattedAmount) {
    if (formattedAmount.isEmpty) return 0.0;

    // إزالة رمز العملة والمسافات
    String cleaned = formattedAmount
        .replaceAll(egpSymbol, '')
        .replaceAll('EGP', '')
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(cleaned) ?? 0.0;
  }

  /// تحويل آمن إلى double
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return 0.0;
      return value;
    }
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// تقريب لأقرب منزلتين عشريتين
  static double round(dynamic value) {
    final num = toDouble(value);
    return (num * 100).round() / 100;
  }
}
