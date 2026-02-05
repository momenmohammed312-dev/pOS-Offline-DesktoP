import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/app_database.dart';

class ExportService {
  static Future<void> exportToCSV({
    required List<Map<String, dynamic>> data,
    required String reportType,
    required String fileName,
  }) async {
    try {
      if (data.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      final csvData = _convertToCSV(data, reportType);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.csv');
      await file.writeAsString(csvData);
    } catch (e) {
      throw Exception('فشل في تصدير CSV: $e');
    }
  }

  static Future<void> exportToExcel({
    required List<Map<String, dynamic>> data,
    required String reportType,
    required String fileName,
  }) async {
    try {
      if (data.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['التقارير'];

      // Add headers
      final headers = _getHeaders(reportType);
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = excel.TextCellValue(
          headers[i],
        );
      }

      // Add data rows
      for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final row = data[rowIndex];
        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          final cellValue = row[headers[colIndex]]?.toString() ?? '';
          sheet
              .cell(
                excel.CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = excel.TextCellValue(
            cellValue,
          );
        }
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.xlsx');
      final excelBytes = excelFile.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      } else {
        throw Exception('فشل في حفظ ملف Excel');
      }
    } catch (e) {
      throw Exception('فشل في تصدير Excel: $e');
    }
  }

  static Future<void> exportToPDF({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
    String? fileName,
  }) async {
    try {
      // For now, just export to CSV with PDF extension
      // In a real implementation, you would use a PDF library
      final csvData = _convertToCSV(data, 'custom');
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${fileName ?? title}.pdf');
      await file.writeAsString(csvData);
    } catch (e) {
      throw Exception('فشل في تصدير PDF: $e');
    }
  }

  static Future<void> exportCustomerStatement({
    required AppDatabase db,
    required String customerName,
    required List<Map<String, dynamic>> transactions,
    String? openingBalance,
    String? currentBalance,
  }) async {
    try {
      final data = <Map<String, dynamic>>[];

      // Add summary rows
      if (openingBalance != null) {
        data.add({
          'التاريخ': 'الرصيد الافتتاحي',
          'الوصف': openingBalance,
          'مدين': '',
          'رصيد': '',
        });
      }

      data.addAll(transactions);

      if (currentBalance != null) {
        data.add({
          'التاريخ': 'الرصيد الحالي',
          'الوصف': currentBalance,
          'مدين': '',
          'رصيد': '',
        });
      }

      final csvData = _convertToCSV(data, 'customer_statement');
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/كشف_حساب_$customerName.csv');
      await file.writeAsString(csvData);
    } catch (e) {
      throw Exception('فشل في تصدير كشف الحساب: $e');
    }
  }

  static Future<void> exportSalesReport({
    required String title,
    required List<Map<String, dynamic>> data,
    String? fileName,
  }) async {
    try {
      final csvData = _convertToCSV(data, 'sales');
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${fileName ?? title}.csv');
      await file.writeAsString(csvData);
    } catch (e) {
      throw Exception('فشل في تصدير تقرير المبيعات: $e');
    }
  }

  static String _convertToCSV(
    List<Map<String, dynamic>> data,
    String reportType,
  ) {
    if (data.isEmpty) return '';

    final headers = _getHeaders(reportType);
    final csvData = <String>[];

    // Add headers
    csvData.add(headers.map((h) => '"$h"').join(','));

    // Add data rows
    for (final row in data) {
      final rowData = headers.map((h) => '"${row[h] ?? ''}"').join(',');
      csvData.add(rowData);
    }

    return csvData.join('\n');
  }

  static List<String> _getHeaders(String reportType) {
    switch (reportType) {
      case 'sales':
        return [
          'رقم الفاتورة',
          'اسم العميل',
          'التاريخ',
          'المبلغ الإجمالي',
          'المدفوع',
          'الحالة',
        ];
      case 'customers':
        return ['اسم العميل', 'رقم الهاتف', 'الرصيد', 'عدد الفواتير'];
      case 'suppliers':
        return ['اسم المورد', 'رقم الهاتف', 'الرصيد', 'عدد المشتريات'];
      case 'products':
        return ['اسم المنتج', 'الفئة', 'الكمية', 'السعر', 'إجمالي المبيعات'];
      case 'customer_statement':
        return ['التاريخ', 'الوصف', 'مدين', 'رصيد'];
      case 'custom':
        return ['التاريخ', 'الوصف', 'المبلغ', 'النوع'];
      default:
        return [];
    }
  }
}
