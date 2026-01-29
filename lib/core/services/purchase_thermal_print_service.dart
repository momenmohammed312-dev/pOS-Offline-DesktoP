import 'dart:developer' as developer;

import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/dao/enhanced_purchase_dao.dart';

class PurchaseThermalPrintService {
  final EnhancedPurchaseDao _purchaseDao;

  PurchaseThermalPrintService(AppDatabase database)
    : _purchaseDao = EnhancedPurchaseDao(database);

  Future<void> printPurchaseReceipt(int purchaseId) async {
    try {
      // Get purchase data
      final purchase = await _purchaseDao.getPurchaseById(purchaseId);
      if (purchase == null) {
        throw Exception('فاتورة المشتريات غير موجودة');
      }

      // Get purchase items
      final items = await _purchaseDao.getItemsByPurchase(purchaseId);

      // Get supplier info
      final supplier = await _purchaseDao.getSupplierById(purchase.supplierId);

      // Generate thermal receipt content
      final receiptContent = _generateThermalReceipt(purchase, supplier, items);

      // Print to thermal printer
      await _printToThermalPrinter(receiptContent);
    } catch (e) {
      throw Exception('خطأ في طباعة الإيصال الحراري: $e');
    }
  }

  Future<void> printPurchaseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get purchases data
      List<EnhancedPurchase> purchases;
      if (startDate != null && endDate != null) {
        purchases = await _purchaseDao.getAllPurchases();
        purchases = purchases.where((purchase) {
          return purchase.purchaseDate.isAfter(
                startDate.subtract(Duration(days: 1)),
              ) &&
              purchase.purchaseDate.isBefore(endDate.add(Duration(days: 1)));
        }).toList();
      } else {
        purchases = await _purchaseDao.getAllPurchases();
      }

      // Generate summary content
      final summaryContent = _generateThermalSummary(
        purchases,
        startDate,
        endDate,
      );

      // Print to thermal printer
      await _printToThermalPrinter(summaryContent);
    } catch (e) {
      throw Exception('خطأ في طباعة الملخص الحراري: $e');
    }
  }

  Future<void> printSupplierStatement(int supplierId) async {
    try {
      // Get supplier data
      final supplier = await _purchaseDao.getSupplierById(supplierId);
      if (supplier == null) {
        throw Exception('المورد غير موجود');
      }

      // Get supplier purchases and payments
      final purchases = await _purchaseDao.getPurchasesBySupplier(supplierId);
      final payments = await _purchaseDao.getPaymentsBySupplier(supplierId);

      // Calculate totals
      final totalPurchases = purchases.fold(
        0.0,
        (sum, p) => sum + p.totalAmount,
      );
      final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
      final remainingBalance = totalPurchases - totalPaid;

      // Generate statement content
      final statementContent = _generateThermalStatement(
        supplier,
        purchases,
        payments,
        remainingBalance,
      );

      // Print to thermal printer
      await _printToThermalPrinter(statementContent);
    } catch (e) {
      throw Exception('خطأ في طباعة كشف الحساب الحراري: $e');
    }
  }

  String _generateThermalReceipt(
    EnhancedPurchase purchase,
    EnhancedSupplier? supplier,
    List<EnhancedPurchaseItem> items,
  ) {
    final lines = <String>[];

    // Header
    lines.add('================================');
    lines.add('      إيصال استلام بضاعة');
    lines.add('================================');
    lines.add('');

    // Company info
    lines.add('شركة MO2 للتجارة');
    lines.add('رقم التسجيل: 123456');
    lines.add('الهاتف: 01234567890');
    lines.add('');

    // Receipt info
    lines.add('رقم الإيصال: ${purchase.purchaseNumber}');
    lines.add(
      'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(purchase.purchaseDate)}',
    );
    lines.add('الكاشير: admin');
    lines.add('');

    // Supplier info
    if (supplier != null) {
      lines.add('المورد: ${supplier.businessName}');
      lines.add('هاتف: ${supplier.phone}');
      lines.add('');
    }

    // Items header
    lines.add('الصنف        الكمية  السعر  الإجمالي');
    lines.add('--------------------------------');

    // Items
    for (final item in items) {
      final name = _truncateText(item.productName, 12);
      final quantity = item.quantity.toString().padLeft(4);
      final price = item.unitPrice.toStringAsFixed(2).padLeft(7);
      final total = item.totalPrice.toStringAsFixed(2).padLeft(8);

      lines.add('$name $quantity $price $total');
    }

    lines.add('--------------------------------');

    // Totals
    lines.add(
      'الإجمالي: ${purchase.totalAmount.toStringAsFixed(2).padLeft(20)} ج.م',
    );
    lines.add(
      'المدفوع: ${purchase.paidAmount.toStringAsFixed(2).padLeft(20)} ج.م',
    );
    lines.add(
      'المتبقي: ${purchase.remainingAmount.toStringAsFixed(2).padLeft(20)} ج.م',
    );
    lines.add('');

    // Payment method
    lines.add('طريقة الدفع: ${_getPaymentMethodLabel(purchase.paymentMethod)}');
    lines.add('نوع الفاتورة: ${purchase.isCreditPurchase ? 'آجل' : 'نقدي'}');
    lines.add('');

    // Footer
    lines.add('شكراً لتعاملكم معنا');
    lines.add('================================');
    lines.add('Developed by MO2');
    lines.add('================================');

    return lines.join('\n');
  }

  String _generateThermalSummary(
    List<EnhancedPurchase> purchases,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final lines = <String>[];

    // Header
    lines.add('================================');
    lines.add('      ملخص المشتريات');
    lines.add('================================');
    lines.add('');

    // Period
    if (startDate != null && endDate != null) {
      lines.add('الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)}');
      lines.add('       : ${DateFormat('yyyy-MM-dd').format(endDate)}');
    } else {
      lines.add('الفترة: جميع الفترات');
    }
    lines.add('');

    // Calculate statistics
    final totalPurchases = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
    final creditPurchases = purchases.where((p) => p.isCreditPurchase).toList();
    final cashPurchases = purchases.where((p) => !p.isCreditPurchase).toList();

    final creditTotal = creditPurchases.fold(
      0.0,
      (sum, p) => sum + p.totalAmount,
    );
    final cashTotal = cashPurchases.fold(0.0, (sum, p) => sum + p.totalAmount);

    // Summary
    lines.add('إجمالي الفواتير: ${purchases.length}');
    lines.add('إجمالي المشتريات: ${totalPurchases.toStringAsFixed(2)} ج.م');
    lines.add('');
    lines.add('المشتريات الآجلة: ${creditTotal.toStringAsFixed(2)} ج.م');
    lines.add('المشتريات النقدية: ${cashTotal.toStringAsFixed(2)} ج.م');
    lines.add('');

    // Average
    final averagePurchase = purchases.isNotEmpty
        ? totalPurchases / purchases.length
        : 0.0;
    lines.add('متوسط الفاتورة: ${averagePurchase.toStringAsFixed(2)} ج.م');
    lines.add('');

    // Footer
    lines.add('================================');
    lines.add('Developed by MO2');
    lines.add('================================');

    return lines.join('\n');
  }

  String _generateThermalStatement(
    EnhancedSupplier supplier,
    List<EnhancedPurchase> purchases,
    List<SupplierPayment> payments,
    double remainingBalance,
  ) {
    final lines = <String>[];

    // Header
    lines.add('================================');
    lines.add('      كشف حساب المورد');
    lines.add('================================');
    lines.add('');

    // Supplier info
    lines.add('المورد: ${supplier.businessName}');
    lines.add('الهاتف: ${supplier.phone}');
    if (supplier.address != null) {
      lines.add('العنوان: ${supplier.address}');
    }
    lines.add('');

    // Current balance
    lines.add('الرصيد الحالي: ${remainingBalance.toStringAsFixed(2)} ج.م');
    lines.add('');

    // Transactions header
    lines.add('التاريخ      النوع      المبلغ     الرصيد');
    lines.add('----------------------------------------');

    // Combine and sort transactions
    final transactions = <Map<String, dynamic>>[];

    // Add purchases
    for (final purchase in purchases) {
      transactions.add({
        'date': purchase.purchaseDate,
        'type': 'شراء',
        'amount': purchase.totalAmount,
        'reference': purchase.purchaseNumber,
      });
    }

    // Add payments
    for (final payment in payments) {
      transactions.add({
        'date': payment.paymentDate,
        'type': 'دفع',
        'amount': -payment.amount,
        'reference': payment.paymentNumber,
      });
    }

    // Sort by date
    transactions.sort((a, b) => a['date'].compareTo(b['date']));

    // Calculate running balance
    double runningBalance = 0.0;
    for (final transaction in transactions) {
      runningBalance += transaction['amount'];

      final date = DateFormat('MM/dd').format(transaction['date']);
      final type = transaction['type'].toString().padRight(6);
      final amount = transaction['amount'].toStringAsFixed(2).padLeft(8);
      final balance = runningBalance.toStringAsFixed(2).padLeft(9);

      lines.add('$date $type $amount $balance');
    }

    lines.add('----------------------------------------');

    // Summary
    final totalPurchases = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
    final totalPayments = payments.fold(0.0, (sum, p) => sum + p.amount);

    lines.add('إجمالي المشتريات: ${totalPurchases.toStringAsFixed(2)} ج.م');
    lines.add('إجمالي المدفوعات: ${totalPayments.toStringAsFixed(2)} ج.م');
    lines.add('الرصيد النهائي: ${remainingBalance.toStringAsFixed(2)} ج.م');
    lines.add('');

    // Footer
    lines.add('================================');
    lines.add('Developed by MO2');
    lines.add('================================');

    return lines.join('\n');
  }

  Future<void> _printToThermalPrinter(String content) async {
    try {
      // In a real implementation, this would interface with the actual thermal printer
      // For now, we'll simulate the printing process

      developer.log('=== THERMAL PRINTER OUTPUT ===');
      developer.log(content);
      developer.log('=== END OF PRINT JOB ===');

      // Simulate printer communication delay
      await Future.delayed(Duration(milliseconds: 500));

      // In real implementation, you would:
      // 1. Connect to thermal printer via Bluetooth/USB
      // 2. Send ESC/POS commands
      // 3. Handle printer status and errors
      // 4. Cut paper if supported
    } catch (e) {
      throw Exception('فشل الاتصال بالطابعة الحرارية: $e');
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'credit':
        return 'آجل';
      case 'bank_transfer':
        return 'تحويل بنكي';
      case 'check':
        return 'شيك';
      default:
        return method;
    }
  }

  // Advanced thermal printing features

  Future<void> printBarcodeLabel(
    String barcode,
    String productName,
    double price,
  ) async {
    final lines = <String>[];

    lines.add('================================');
    lines.add(_truncateText(productName, 20));
    lines.add('');
    lines.add('السعر: ${price.toStringAsFixed(2)} ج.م');
    lines.add('');
    lines.add('الباركود: $barcode');
    lines.add('================================');

    await _printToThermalPrinter(lines.join('\n'));
  }

  Future<void> printPriceTags(List<Map<String, dynamic>> products) async {
    for (final product in products) {
      final lines = <String>[];

      lines.add('====================');
      lines.add(_truncateText(product['name'], 18));
      lines.add('');
      lines.add('السعر: ${product['price'].toStringAsFixed(2)} ج.م');
      if (product['barcode'] != null) {
        lines.add('الباركود: ${product['barcode']}');
      }
      lines.add('====================');
      lines.add('');

      await _printToThermalPrinter(lines.join('\n'));
    }
  }

  Future<void> printDailyReport(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final purchases = await _purchaseDao.getAllPurchases();
      final dayPurchases = purchases
          .where(
            (p) =>
                p.purchaseDate.isAfter(startOfDay) &&
                p.purchaseDate.isBefore(endOfDay),
          )
          .toList();

      final lines = <String>[];

      lines.add('================================');
      lines.add('      تقرير يومي');
      lines.add('================================');
      lines.add('');
      lines.add('التاريخ: ${DateFormat('yyyy-MM-dd').format(date)}');
      lines.add('');

      final totalSales = dayPurchases.fold(
        0.0,
        (sum, p) => sum + p.totalAmount,
      );
      lines.add('عدد الفواتير: ${dayPurchases.length}');
      lines.add('إجمالي المبيعات: ${totalSales.toStringAsFixed(2)} ج.م');
      lines.add('');

      if (dayPurchases.isNotEmpty) {
        lines.add('أخر 5 فواتير:');
        lines.add('--------------------------------');

        final recentPurchases = dayPurchases.take(5).toList();
        for (final purchase in recentPurchases) {
          lines.add(
            '${purchase.purchaseNumber} - ${purchase.totalAmount.toStringAsFixed(2)} ج.م',
          );
        }
      }

      lines.add('================================');
      lines.add('Developed by MO2');
      lines.add('================================');

      await _printToThermalPrinter(lines.join('\n'));
    } catch (e) {
      throw Exception('خطأ في طباعة التقرير اليومي: $e');
    }
  }

  Future<void> testPrinter() async {
    final lines = <String>[];

    lines.add('================================');
    lines.add('      اختبار الطابعة');
    lines.add('================================');
    lines.add('');
    lines.add('اختبار الطباعة الحرارية');
    lines.add(
      'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
    );
    lines.add('');
    lines.add('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    lines.add('abcdefghijklmnopqrstuvwxyz');
    lines.add('0123456789');
    lines.add('!@#\$%^&*()_+-=[]{}|;:,.<>?');
    lines.add('');
    lines.add('الخط العربي:');
    lines.add('ابتثجحخدذرزسشصضطظعغفقكلمنهوي');
    lines.add('================================');
    lines.add('Developed by MO2');
    lines.add('================================');

    await _printToThermalPrinter(lines.join('\n'));
  }

  Future<void> printDuplicateReceipt(int purchaseId) async {
    await printPurchaseReceipt(purchaseId);

    // Add duplicate mark
    final duplicateLines = <String>[];
    duplicateLines.add('');
    duplicateLines.add('*** نسخة مكررة ***');
    duplicateLines.add(
      'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
    );
    duplicateLines.add('================================');

    await _printToThermalPrinter(duplicateLines.join('\n'));
  }
}
