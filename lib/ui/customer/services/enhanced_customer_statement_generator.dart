import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/utils/arabic_helper.dart';

class EnhancedCustomerStatementGenerator {
  static const String _branding = 'Developed by MO2';

  // Font loading
  static Future<Map<String, pw.Font?>> _loadFonts() async {
    pw.Font? arabicFont;
    pw.Font? arabicBoldFont;
    pw.Font? latinFont;

    try {
      // Load Arabic regular font
      final regularFontData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      if (regularFontData.lengthInBytes > 100) {
        arabicFont = pw.Font.ttf(regularFontData);
      }

      // Load Arabic bold font (using regular as fallback)
      final boldFontData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      if (boldFontData.lengthInBytes > 100) {
        arabicBoldFont = pw.Font.ttf(boldFontData);
      }
    } catch (e) {
      debugPrint('Failed to load Arabic fonts: $e');
    }

    // Latin font fallback
    latinFont = pw.Font.helvetica();

    return {
      'arabic': arabicFont,
      'arabicBold': arabicBoldFont,
      'latin': latinFont,
    };
  }

  // Helper method to get invoice items with products
  static Future<List<Map<String, dynamic>>> _getInvoiceItemsWithProducts(
    AppDatabase db,
    int invoiceId,
  ) async {
    try {
      final items = await db.invoiceDao.getItemsWithProductsByInvoice(
        invoiceId,
      );
      return items.map((itemWithProduct) {
        final item = itemWithProduct.$1;
        final product = itemWithProduct.$2;
        final unitPrice = item.quantity > 0 ? item.price / item.quantity : 0.0;

        return {
          'productName': product?.name ?? 'منتج ${item.productId}',
          'quantity': item.quantity,
          'unitPrice': unitPrice,
          'total': item.price,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error in _getInvoiceItemsWithProducts: $e');
      return [];
    }
  }

  // Generate enhanced customer statement PDF
  static Future<void> generateStatement({
    required AppDatabase db,
    required String customerId,
    required String customerName,
    required DateTime fromDate,
    required DateTime toDate,
    required double openingBalance,
    required double currentBalance,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();

    // Get transactions
    final transactions = await _getEnhancedTransactions(
      db,
      customerId,
      fromDate,
      toDate,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header & Branding Section
                _buildHeaderSection(
                  fonts,
                  customerName,
                  openingBalance,
                  currentBalance,
                  fromDate,
                  toDate,
                ),
                pw.SizedBox(height: 20),

                // Main Transaction Table
                _buildMainTransactionTable(transactions, fonts),
                pw.SizedBox(height: 20),

                // Footer
                _buildFooterSection(fonts),
              ],
            ),
          );
        },
      ),
    );

    await _saveAndPrintPdf(pdf, 'كشف حساب $customerName.pdf');
  }

  // Header & Branding Section
  static pw.Widget _buildHeaderSection(
    Map<String, pw.Font?> fonts,
    String customerName,
    double openingBalance,
    double currentBalance,
    DateTime fromDate,
    DateTime toDate,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Developer Branding
          pw.Text(
            _branding,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
              font: fonts['arabicBold'],
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),

          // Summary Info
          pw.Container(
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Customer Name
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      ArabicHelper.reshapedText('اسم العميل: $customerName'),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        font: fonts['arabicBold'],
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      ArabicHelper.reshapedText('كشف حساب عميل'),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        font: fonts['arabicBold'],
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Current Balance (Red if debt)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      ArabicHelper.reshapedText(
                        'الرصيد الحالي: ${formatCurrency(currentBalance)}',
                      ),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: currentBalance > 0
                            ? PdfColors.red
                            : PdfColors.green,
                        font: fonts['arabicBold'],
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      ArabicHelper.reshapedText(
                        'الرصيد السابق: ${formatCurrency(openingBalance)}',
                      ),
                      style: pw.TextStyle(fontSize: 12, font: fonts['arabic']),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Date Range
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      ArabicHelper.reshapedText(
                        'الفترة: من ${DateFormat('yyyy/MM/dd').format(fromDate)} إلى ${DateFormat('yyyy/MM/dd').format(toDate)}',
                      ),
                      style: pw.TextStyle(fontSize: 12, font: fonts['arabic']),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Main Transaction Table Layout
  static pw.Widget _buildMainTransactionTable(
    List<Map<String, dynamic>> transactions,
    Map<String, pw.Font?> fonts,
  ) {
    return pw.Expanded(
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.8), // ID (الرقم)
          1: const pw.FlexColumnWidth(1.2), // Date (التاريخ)
          2: const pw.FlexColumnWidth(2.5), // Statement (البيان)
          3: const pw.FlexColumnWidth(1.0), // Debit (مدين)
          4: const pw.FlexColumnWidth(1.0), // Credit (دائن)
          5: const pw.FlexColumnWidth(1.2), // Balance (الرصيد)
        },
        children: [
          // Table Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              _buildHeaderCell('الرقم', fonts['arabicBold']),
              _buildHeaderCell('التاريخ', fonts['arabicBold']),
              _buildHeaderCell('البيان', fonts['arabicBold']),
              _buildHeaderCell('مدين', fonts['arabicBold']),
              _buildHeaderCell('دائن', fonts['arabicBold']),
              _buildHeaderCell('الرصيد', fonts['arabicBold']),
            ],
          ),
          // Transaction Rows
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            return pw.TableRow(
              children: [
                // ID
                _buildDataCell('${index + 1}', fonts['arabic'], isBold: true),
                // Date
                _buildDataCell(
                  DateFormat('yyyy/MM/dd').format(transaction['date']),
                  fonts['arabic'],
                ),
                // Statement (with nested details for sales)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Main transaction description
                      pw.Text(
                        ArabicHelper.reshapedText(
                          transaction['description'] ?? '',
                        ),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: fonts['arabicBold'],
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      // Nested itemization for sales
                      if (transaction['type'] == 'sale' &&
                          transaction['items'] != null &&
                          transaction['items'].isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        _buildNestedItemization(transaction['items'], fonts),
                      ],
                    ],
                  ),
                ),
                // Debit
                _buildDataCell(
                  formatCurrency(transaction['debit'] ?? 0.0),
                  fonts['arabic'],
                  isBold: true,
                ),
                // Credit
                _buildDataCell(
                  formatCurrency(transaction['credit'] ?? 0.0),
                  fonts['arabic'],
                  isBold: true,
                ),
                // Balance (Red for debt)
                _buildDataCell(
                  formatCurrency(transaction['balance'] ?? 0.0),
                  fonts['arabic'],
                  isBold: true,
                  color: (transaction['balance'] ?? 0.0) > 0
                      ? PdfColors.red
                      : PdfColors.black,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Nested Itemization for Sales
  static pw.Widget _buildNestedItemization(
    List<dynamic> items,
    Map<String, pw.Font?> fonts,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 8, top: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Items Table Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    ArabicHelper.reshapedText('الصنف'),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      font: fonts['arabicBold'],
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    ArabicHelper.reshapedText('كمية'),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      font: fonts['arabicBold'],
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    ArabicHelper.reshapedText('سعر'),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      font: fonts['arabicBold'],
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    ArabicHelper.reshapedText('إجمالي'),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      font: fonts['arabicBold'],
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items.map(
            (item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      ArabicHelper.reshapedText(item['productName'] ?? ''),
                      style: pw.TextStyle(fontSize: 8, font: fonts['arabic']),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${item['quantity'] ?? 0}',
                      style: pw.TextStyle(fontSize: 8, font: fonts['arabic']),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      formatCurrency((item['unitPrice'] ?? 0.0).toDouble()),
                      style: pw.TextStyle(fontSize: 8, font: fonts['arabic']),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Footer Section
  static pw.Widget _buildFooterSection(Map<String, pw.Font?> fonts) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                _branding,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                  font: fonts['arabicBold'],
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                ArabicHelper.reshapedText(
                  'تم الإنشاء في ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                ),
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  font: fonts['arabic'],
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for table cells
  static pw.Widget _buildHeaderCell(String text, pw.Font? font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        ArabicHelper.reshapedText(text),
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          font: font,
          fontFallback: [pw.Font.helvetica()],
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget _buildDataCell(
    String text,
    pw.Font? font, {
    bool isBold = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        ArabicHelper.reshapedText(text),
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: font,
          fontFallback: [pw.Font.helvetica()],
          color: color,
          fontSize: isBold ? 11 : 10,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  // Get enhanced transactions with product details
  static Future<List<Map<String, dynamic>>> _getEnhancedTransactions(
    AppDatabase db,
    String customerId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final transactions = <Map<String, dynamic>>[];
    double runningBalance = 0.0;

    try {
      // Get invoices for the customer in date range
      final allInvoices = await db.invoiceDao.getInvoicesByDateRange(
        fromDate,
        toDate,
      );
      final invoices = allInvoices
          .where((invoice) => invoice.customerId == customerId)
          .toList();

      // Get payments for the customer in date range
      final payments = await db.ledgerDao.getTransactionsByDateRange(
        'Customer',
        customerId,
        fromDate,
        toDate,
      );

      // Combine all transactions and sort by date
      final allTransactions = <Map<String, dynamic>>[];

      // Add invoices
      for (final invoice in invoices) {
        final items = await _getInvoiceItemsWithProducts(db, invoice.id);
        allTransactions.add({
          'date': invoice.date,
          'type': 'sale',
          'description':
              'مبيعات - فاتورة #${invoice.invoiceNumber ?? invoice.id}',
          'debit': invoice.totalAmount,
          'credit': 0.0,
          'items': items,
          'invoiceId': invoice.id,
        });
      }

      // Add payments
      for (final payment in payments) {
        allTransactions.add({
          'date': payment.date,
          'type': 'payment',
          'description': 'استلام نقدية - ${payment.description}',
          'debit': 0.0,
          'credit': payment.credit,
          'items': <dynamic>[],
        });
      }

      // Sort by date and calculate running balance
      allTransactions.sort((a, b) => a['date'].compareTo(b['date']));

      for (final transaction in allTransactions) {
        final debit = transaction['debit'] as double;
        final credit = transaction['credit'] as double;
        runningBalance += debit - credit;

        transaction['balance'] = runningBalance;
        transactions.add(transaction);
      }
    } catch (e) {
      debugPrint('Error getting enhanced transactions: $e');
    }

    return transactions;
  }

  // Format currency (public for testing)
  static String formatCurrency(double amount) {
    if (amount.isNaN) return '0.00 ج.م';
    final formatted = NumberFormat.currency(
      locale: 'en_EG',
      symbol: '',
      decimalDigits: 2,
    ).format(amount);
    return '$formatted ج.م';
  }

  // Save and print PDF
  static Future<void> _saveAndPrintPdf(pw.Document pdf, String fileName) async {
    try {
      final output = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => output,
        name: fileName,
      );
    } catch (e) {
      debugPrint('Print error: $e');
      // Fallback: save to file
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = path.join(directory.path, fileName);
        final file = File(filePath);
        final output = await pdf.save();
        await file.writeAsBytes(output);
        debugPrint('PDF saved to: $filePath');
      } catch (saveError) {
        debugPrint('Error saving PDF: $saveError');
        rethrow;
      }
    }
  }
}
