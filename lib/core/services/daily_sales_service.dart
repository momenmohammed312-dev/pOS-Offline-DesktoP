import 'package:intl/intl.dart';
import '../database/app_database.dart';

class DailySalesService {
  final AppDatabase db;

  DailySalesService(this.db);

  // Get today's date string (YYYY-MM-DD)
  String get todayDateString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Get sales for a specific date
  Future<double> getSalesForDate(String dateString) async {
    final date = DateFormat('yyyy-MM-dd').parse(dateString);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final invoices = await db.invoiceDao.getInvoicesByDateRange(
      startOfDay,
      endOfDay,
    );

    return invoices.fold<double>(
      0.0,
      (sum, invoice) => sum + invoice.totalAmount,
    );
  }

  // Get today's sales
  Future<double> getTodaySales() async {
    return await getSalesForDate(todayDateString);
  }

  // Get sales count for a specific date
  Future<int> getSalesCountForDate(String dateString) async {
    final date = DateFormat('yyyy-MM-dd').parse(dateString);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final invoices = await db.invoiceDao.getInvoicesByDateRange(
      startOfDay,
      endOfDay,
    );
    return invoices.length;
  }

  // Get today's sales count
  Future<int> getTodaySalesCount() async {
    return await getSalesCountForDate(todayDateString);
  }

  // Get daily sales summary for a date range
  Future<Map<String, Map<String, dynamic>>> getDailySalesSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final Map<String, Map<String, dynamic>> dailySummary = {};

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final dateString = DateFormat('yyyy-MM-dd').format(currentDate);
      final salesAmount = await getSalesForDate(dateString);
      final salesCount = await getSalesCountForDate(dateString);

      dailySummary[dateString] = {
        'date': currentDate,
        'salesAmount': salesAmount,
        'salesCount': salesCount,
        'formattedDate': DateFormat('dd/MM/yyyy').format(currentDate),
        'dayName': _getDayNameArabic(currentDate.weekday),
      };

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dailySummary;
  }

  // Get invoices for a specific date
  Future<List<Invoice>> getInvoicesForDate(String dateString) async {
    final date = DateFormat('yyyy-MM-dd').parse(dateString);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await db.invoiceDao.getInvoicesByDateRange(startOfDay, endOfDay);
  }

  // Get Arabic day name
  String _getDayNameArabic(int weekday) {
    switch (weekday) {
      case 1:
        return 'الإثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }

  // Check if it's a new day (for reset functionality)
  bool isNewDay(DateTime lastCheckDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckDay = DateTime(
      lastCheckDate.year,
      lastCheckDate.month,
      lastCheckDate.day,
    );

    return today.isAfter(lastCheckDay);
  }

  // Get month summary
  Future<Map<String, dynamic>> getMonthSummary(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final dailySummary = await getDailySalesSummary(startDate, endDate);

    double totalSales = 0.0;
    int totalTransactions = 0;
    int daysWithSales = 0;

    for (final dayData in dailySummary.values) {
      totalSales += dayData['salesAmount'] as double;
      totalTransactions += dayData['salesCount'] as int;
      if ((dayData['salesAmount'] as double) > 0) {
        daysWithSales++;
      }
    }

    return {
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'daysWithSales': daysWithSales,
      'averageDailySales': daysWithSales > 0 ? totalSales / daysWithSales : 0.0,
      'monthName': getMonthNameArabic(month),
      'year': year,
    };
  }

  // Get Arabic month name
  String getMonthNameArabic(int month) {
    switch (month) {
      case 1:
        return 'يناير';
      case 2:
        return 'فبراير';
      case 3:
        return 'مارس';
      case 4:
        return 'أبريل';
      case 5:
        return 'مايو';
      case 6:
        return 'يونيو';
      case 7:
        return 'يوليو';
      case 8:
        return 'أغسطس';
      case 9:
        return 'سبتمبر';
      case 10:
        return 'أكتوبر';
      case 11:
        return 'نوفمبر';
      case 12:
        return 'ديسمبر';
      default:
        return '';
    }
  }
}
