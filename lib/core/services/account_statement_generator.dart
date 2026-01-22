import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/dao/ledger_dao.dart';
import '../utils/arabic_helper.dart';

class AccountStatementGenerator {
  static const String _branding = 'Developed by MO2';
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;
  static pw.Font? _latinFont;

  static Future<void> _loadFonts() async {
    if (_arabicFont == null) {
      try {
        // Load Arabic fonts
        final arabicFontData = await rootBundle.load(
          'assets/fonts/NotoNaskhArabic-Regular.ttf',
        );
        _arabicFont = pw.Font.ttf(arabicFontData);
        _arabicBoldFont =
            _arabicFont; // Use regular font for bold since bold version doesn't exist

        final latinFontData = await rootBundle.load(
          'assets/fonts/DejaVuSans.ttf',
        );
        _latinFont = pw.Font.ttf(latinFontData);
      } catch (e) {
        debugPrint('Failed to load fonts: $e');
        // Fallback to built-in fonts
        _arabicFont = pw.Font.times();
        _arabicBoldFont = pw.Font.timesBold();
        _latinFont = pw.Font.courier(); // Courier has better Unicode support
      }
    }
  }

  // Helper method to get unified theme
  static pw.ThemeData _getTheme() {
    return pw.ThemeData.withFont(base: _arabicFont!, bold: _arabicBoldFont!);
  }

  // Helper method to create TextStyle with proper font fallback
  static pw.TextStyle _getTextStyle({
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.TextStyle(
      font: isBold ? _arabicBoldFont : _arabicFont,
      fontFallback: [_latinFont!],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  Future<Uint8List> generateAccountStatement({
    required String entityName,
    required String entityType,
    required String entityId,
    required DateTime fromDate,
    required DateTime toDate,
    required LedgerDao ledgerDao,
  }) async {
    await _loadFonts();

    // unused bold and font variables removed

    final pdf = pw.Document();

    // Get transactions with running balance
    final transactions = await ledgerDao.getTransactionsWithRunningBalance(
      entityType,
      entityId,
      fromDate,
      toDate,
    );

    // Calculate opening balance
    final runningBalance = await ledgerDao.getRunningBalance(
      entityType,
      entityId,
      upToDate: fromDate.subtract(const Duration(days: 1)),
    );

    // Calculate final balance
    double currentBalance = runningBalance;
    if (transactions.isNotEmpty) {
      currentBalance = transactions.last.runningBalance;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: _getTheme(),
        build: (pw.Context context) => [
          _buildHeader(
            entityName,
            entityType,
            fromDate,
            toDate,
            currentBalance,
          ),
          pw.SizedBox(height: 20),
          // Opening balance removed from header to match export format requirements
          _buildTransactionsTable(transactions),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    String entityName,
    String entityType,
    DateTime fromDate,
    DateTime toDate,
    double currentBalance,
  ) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            ArabicHelper.reshapedText('كشف حساب عميل'),
            style: _getTextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              isBold: true,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow(
                        ArabicHelper.reshapedText('الاسم:'),
                        ArabicHelper.reshapedText(entityName),
                      ),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow(
                        'لنا / علينا:',
                        currentBalance >= 0 ? 'مدين / لنا' : 'دائن / علينا',
                      ),
                    ),
                  ],
                ),
                _buildInfoRow(
                  'المبلغ الإجمالي:',
                  _formatCurrency(currentBalance.abs()),
                ),
                _buildInfoRow(
                  ArabicHelper.reshapedText('نوع الحساب:'),
                  ArabicHelper.reshapedText(
                    entityType == 'Customer' ? 'عميل' : 'مورد',
                  ),
                ),
                _buildInfoRow(
                  ArabicHelper.reshapedText('الفترة:'),
                  '${DateFormat('yyyy/MM/dd').format(fromDate)} - ${DateFormat('yyyy/MM/dd').format(toDate)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              ArabicHelper.reshapedText(label),
              style: _getTextStyle(
                fontWeight: pw.FontWeight.bold,
                isBold: true,
              ),
              textDirection: pw.TextDirection.ltr,
            ),
          ),
          pw.Text(
            ArabicHelper.reshapedText(value),
            textDirection: pw.TextDirection.ltr,
            style: _getTextStyle(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionsTable(
    List<LedgerTransactionWithBalance> transactions,
  ) {
    if (transactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        alignment: pw.Alignment.center,
        child: pw.Text(
          ArabicHelper.reshapedText('لا توجد معاملات في هذه الفترة'),
          style: _getTextStyle(color: PdfColors.grey600),
          textDirection: pw.TextDirection.rtl,
        ),
      );
    }

    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2), // Date
          1: const pw.FlexColumnWidth(1.2), // Receipt#
          2: const pw.FlexColumnWidth(2.5), // Description
          3: const pw.FlexColumnWidth(1), // Debit (لنا)
          4: const pw.FlexColumnWidth(1), // Credit (علينا)
          5: const pw.FlexColumnWidth(1.2), // Balance
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildTableCell(
                ArabicHelper.reshapedText('التاريخ'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('رقم الإيصال'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('البيان / الوصف'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('مدين (لنا)'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('دائن (علينا)'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('الرصيد'),
                isHeader: true,
              ),
            ],
          ),
          // Data rows
          ...transactions.map(
            (tx) => pw.TableRow(
              children: [
                _buildTableCell(
                  DateFormat('yyyy/MM/dd').format(tx.transaction.date),
                ),
                _buildTableCell(tx.transaction.receiptNumber ?? ''),
                _buildTableCell(
                  ArabicHelper.reshapedText(tx.transaction.description),
                ),
                _buildTableCell(
                  tx.transaction.debit > 0
                      ? _formatCurrency(tx.transaction.debit)
                      : '',
                ),
                _buildTableCell(
                  tx.transaction.credit > 0
                      ? _formatCurrency(tx.transaction.credit)
                      : '',
                ),
                _buildTableCell(_formatCurrency(tx.runningBalance)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        ArabicHelper.reshapedText(text),
        style: _getTextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 8,
          isBold: isHeader,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            _branding,
            style: _getTextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            ArabicHelper.reshapedText(
              'تم الاستخراج في ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
            ),
            style: _getTextStyle(fontSize: 8, color: PdfColors.grey500),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_EG',
      symbol: 'ج.م',
      decimalDigits: 2,
    ).format(amount);
  }

  Future<void> printAccountStatement({
    required String entityName,
    required String entityType,
    required String entityId,
    required DateTime fromDate,
    required DateTime toDate,
    required LedgerDao ledgerDao,
    Printer? printer,
  }) async {
    final pdfData = await generateAccountStatement(
      entityName: entityName,
      entityType: entityType,
      entityId: entityId,
      fromDate: fromDate,
      toDate: toDate,
      ledgerDao: ledgerDao,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdfData,
      name: 'Account Statement - $entityName',
      format: PdfPageFormat.a4,
    );
  }
}
