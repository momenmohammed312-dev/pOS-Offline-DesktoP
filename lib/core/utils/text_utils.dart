import 'package:intl/intl.dart';
import 'safe_math.dart';

class TextUtils {
  // ===== تنسيق العملة =====

  static String formatCurrency(dynamic amount) {
    final safeAmount = SafeMath.toDouble(amount);
    // استخدام اللغة الإنجليزية للأرقام مع الرمز العربي للعملة
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '${formatter.format(safeAmount)} ج.م';
  }

  // ===== معالجة النصوص العربية =====

  static String processArabicText(String text) {
    if (text.isEmpty) return text;

    // إزالة المسافات الزائدة
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    // معالجة الحروف الخاصة
    text = _fixArabicCharacters(text);

    return text;
  }

  static String _fixArabicCharacters(String text) {
    // تصحيح الهمزات
    text = text.replaceAll('أ', 'أ');
    text = text.replaceAll('إ', 'إ');
    text = text.replaceAll('آ', 'آ');

    // تصحيح الياء
    text = text.replaceAll('ي', 'ي');
    text = text.replaceAll('ى', 'ى');

    return text;
  }

  // ===== تنسيق الأرقام =====

  static String formatNumber(dynamic number, {int decimals = 2}) {
    final safeNumber = SafeMath.toDouble(number);
    return safeNumber.toStringAsFixed(decimals);
  }

  static String formatWithSeparators(dynamic number) {
    final safeNumber = SafeMath.toDouble(number);
    // استخدام اللغة الإنجليزية للأرقام
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(safeNumber);
  }

  // ===== التواريخ =====

  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    final formatter = DateFormat(format, 'ar_EG');
    return formatter.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss', 'ar_EG');
    return formatter.format(dateTime);
  }

  static String formatDateArabic(DateTime date) {
    final formatter = DateFormat('EEEE، d MMMM yyyy', 'ar_EG');
    return formatter.format(date);
  }
}
