import 'package:flutter/material.dart';

class CustomerValidationService {
  static String? validateCustomerData(String name, String? phone) {
    if (name.isEmpty) return 'الاسم مطلوب';
    if (phone != null && phone.isNotEmpty && phone.length < 10) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 10) {
        return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
      }
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.trim().length < 5) {
        return 'العنوان يجب أن يكون 5 أحرف على الأقل';
      }
    }
    return null;
  }

  static String? validateGstin(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 15) {
        return 'رقم GSTIN يجب أن يكون 15 حرفاً';
      }
      if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
        return 'رقم GSTIN يجب أن يحتوي على أحرف إنجليزية وأرقام فقط';
      }
    }
    return null;
  }

  static String? validateOpeningBalance(String? value) {
    if (value != null && value.isNotEmpty) {
      final balance = double.tryParse(value);
      if (balance == null) {
        return 'الرصيد يجب أن يكون رقماً صحيحاً';
      }
      if (balance < -999999 || balance > 999999) {
        return 'الرصيد يجب أن يكون بين -999999 و 999999';
      }
    }
    return null;
  }
}

class CustomerErrorHandler {
  static void handleCustomerError(
    BuildContext context,
    Object error, {
    String? customMessage,
  }) {
    String errorMessage = customMessage ?? 'حدث خطأ غير متوقع';

    if (error.toString().contains('no such column: created_at')) {
      errorMessage =
          'خطأ في قاعدة البيانات: عمود التاريخ غير موجود. يرجى إعادة تشغيل التطبيق.';
    } else if (error.toString().contains('UNIQUE constraint failed')) {
      errorMessage = 'هذا العميل موجود بالفعل في النظام';
    } else if (error.toString().contains('NOT NULL constraint failed')) {
      errorMessage = 'جميع الحقول المطلوبة يجب ملؤها';
    } else if (error.toString().contains('database is locked')) {
      errorMessage = 'قاعدة البيانات مشغولة حالياً، يرجى المحاولة مرة أخرى';
    } else {
      errorMessage = 'خطأ: ${error.toString()}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessMessage(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
