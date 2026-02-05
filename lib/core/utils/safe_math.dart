class SafeMath {
  /// جمع آمن
  static double add(dynamic a, dynamic b) {
    final numA = _toDouble(a);
    final numB = _toDouble(b);
    final result = numA + numB;
    return _validateResult(result);
  }

  /// طرح آمن
  static double subtract(dynamic a, dynamic b) {
    final numA = _toDouble(a);
    final numB = _toDouble(b);
    final result = numA - numB;
    return _validateResult(result);
  }

  /// ضرب آمن
  static double multiply(dynamic a, dynamic b) {
    final numA = _toDouble(a);
    final numB = _toDouble(b);
    final result = numA * numB;
    return _validateResult(result);
  }

  /// قسمة آمنة
  static double divide(dynamic a, dynamic b) {
    final numA = _toDouble(a);
    final numB = _toDouble(b);

    // منع القسمة على صفر
    if (numB == 0) return 0.0;

    final result = numA / numB;
    return _validateResult(result);
  }

  /// تحويل آمن لـ double
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// تحويل آمن لـ double (داخلي)
  static double _toDouble(dynamic value) {
    return toDouble(value);
  }

  /// التحقق من صحة النتيجة
  static double _validateResult(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value;
  }

  /// حساب النسبة المئوية
  static double percentage(dynamic value, dynamic percent) {
    final numValue = _toDouble(value);
    final numPercent = _toDouble(percent);
    return multiply(numValue, divide(numPercent, 100));
  }

  /// تقريب لأقرب منزلتين عشريتين
  static double round2(dynamic value) {
    final num = _toDouble(value);
    return (num * 100).roundToDouble() / 100;
  }
}
