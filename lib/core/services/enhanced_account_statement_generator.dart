import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/dao/ledger_dao.dart';
import '../database/dao/invoice_dao.dart';
import '../database/dao/customer_dao.dart';
import '../database/app_database.dart';
import '../utils/arabic_helper.dart';

class EnhancedAccountStatementGenerator {
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
    required InvoiceDao invoiceDao,
    required CustomerDao customerDao, // Added CustomerDao parameter
    String branchName = 'الفرع الرئيسي المصنع',
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

    // Get transactions with running balance
    final transactions = await ledgerDao.getTransactionsWithRunningBalance(
      entityType,
      entityId,
      fromDate,
      toDate,
    );

    // Calculate opening balance (currently not displayed in header)
    await ledgerDao.getRunningBalance(
      entityType,
      entityId,
      upToDate: fromDate.subtract(const Duration(days: 1)),
    );

    // Get enhanced transaction data with invoice items
    final enhancedTransactions = await _getEnhancedTransactions(
      transactions,
      invoiceDao,
    );

    // Calculate closing balance
    double closingBalance = 0.0;
    if (transactions.isNotEmpty) {
      closingBalance = transactions.last.runningBalance;
    } else {
      // If no transactions in range, fetch checking account balance up to toDate
      // Or simpler: just use getCustomerBalance from ledgerDao if available, or calc manually.
      // Given the dao methods, let's trust the last running balance or previous balance.
      closingBalance = await ledgerDao.getRunningBalance(
        entityType,
        entityId,
        upToDate: toDate,
      );
    }

    // Add opening balance for Customers
    if (entityType == 'Customer') {
      final customer = await customerDao.getCustomerById(entityId);
      if (customer != null) {
        closingBalance += customer.openingBalance;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: _getTheme(),
        build: (pw.Context context) => [
          _buildHeader(
            entityName,
            entityType,
            fromDate,
            toDate,
            branchName,
            closingBalance,
          ), // Pass balance
          pw.SizedBox(height: 10),
          // Opening balance removed from header to match export format requirements
          _buildTransactionsTable(enhancedTransactions),
          pw.SizedBox(height: 10),
          _buildFooter(context),
        ],
      ),
    );

    return pdf.save();
  }

  Future<List<EnhancedTransaction>> _getEnhancedTransactions(
    List<LedgerTransactionWithBalance> transactions,
    InvoiceDao invoiceDao,
  ) async {
    final enhancedTransactions = <EnhancedTransaction>[];

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      List<InvoiceItemWithProduct>? invoiceItems;

      // If this is a sale transaction, try to get invoice items
      if (tx.transaction.origin == 'sale' &&
          tx.transaction.receiptNumber != null) {
        try {
          // Fix for Issue G: Robust ID parsing
          // Remove any non-digit characters to handle "INV-123", "Sale #123", etc.
          String cleanId = tx.transaction.receiptNumber!.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

          int? invoiceId = int.tryParse(cleanId);

          // If robust parsing fails or returns 0 (invalid), failback to original string lookup
          if (invoiceId == null || invoiceId == 0) {
            final invoice = await invoiceDao.getInvoiceByNumber(
              tx.transaction.receiptNumber!,
            );
            if (invoice != null) {
              invoiceId = invoice.id;
            }
          }

          if (invoiceId != null) {
            final items = await invoiceDao.getItemsWithProductsByInvoice(
              invoiceId,
            );
            invoiceItems = items
                .map(
                  (item) => InvoiceItemWithProduct(
                    invoiceItem: item.$1,
                    product: item.$2,
                  ),
                )
                .toList();
          }
        } catch (e) {
          // If we can't get invoice items, continue without them
          debugPrint(
            'Error fetching invoice items for transaction ${tx.transaction.id}: $e',
          );
        }
      }

      enhancedTransactions.add(
        EnhancedTransaction(
          serialNumber: i + 1,
          transaction: tx,
          invoiceItems: invoiceItems ?? [],
          discount: 0.0,
          total: tx.transaction.debit > 0
              ? tx.transaction.debit
              : tx.transaction.credit,
          westernAmount: 0.0,
          paidAmount: tx.transaction.paymentMethod == 'cash'
              ? (tx.transaction.debit > 0 ? tx.transaction.debit : 0)
              : 0,
          expenses: 0.0,
          notes: '',
        ),
      );
    }

    return enhancedTransactions;
  }

  pw.Widget _buildHeader(
    String entityName,
    String entityType,
    DateTime fromDate,
    DateTime toDate,
    String branchName,
    double closingBalance, // New parameter
  ) {
    // Determine label and color based on balance
    String balanceLabel;
    String balanceValue = _formatCurrency(closingBalance.abs());
    PdfColor balanceColor;

    // Fix for Issue H: Strict Labels per User SOP
    if (closingBalance > 0) {
      // Customer owes us (Receivable) -> Debt/Debit
      balanceLabel = 'ديون مدين (لنا)';
      balanceColor = PdfColors.red;
    } else if (closingBalance < 0) {
      // We owe customer (Payable) -> Credit
      balanceLabel = 'دائن (علينا)';
      balanceColor = PdfColors.green;
    } else {
      balanceLabel = 'رصيد متزن';
      balanceColor = PdfColors.black;
    }

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
                        ArabicHelper.reshapedText('اسم العميل:'),
                        ArabicHelper.reshapedText(entityName),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          ArabicHelper.reshapedText(
                            '$balanceLabel: $balanceValue',
                          ),
                          style: _getTextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: balanceColor,
                            isBold: true,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildInfoRow(
                  ArabicHelper.reshapedText('التاريخ:'),
                  DateFormat('yyyy/MM/dd').format(DateTime.now()),
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
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            alignment: pw.Alignment.center,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  ArabicHelper.reshapedText('خيارات:'),
                  style: _getTextStyle(
                    fontWeight: pw.FontWeight.bold,
                    isBold: true,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  ArabicHelper.reshapedText(
                    '• عرض تفاصيل المنتجات في عمود البيان',
                  ),
                  style: _getTextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  ArabicHelper.reshapedText(
                    '• يتضمن معلومات الفرع في الترويسة',
                  ),
                  style: _getTextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  ArabicHelper.reshapedText(
                    '• يحتوي على أرقام الصفحات والتوقيت في التذييل',
                  ),
                  style: _getTextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  ArabicHelper.reshapedText('• يدعم العلامة التجارية MO2.com'),
                  style: _getTextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
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
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: _getTextStyle(
                fontWeight: pw.FontWeight.bold,
                isBold: true,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: _getTextStyle(),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionsTable(List<EnhancedTransaction> transactions) {
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
          0: const pw.FlexColumnWidth(0.8), // م (Serial)
          1: const pw.FlexColumnWidth(1), // التاريخ (Date)
          2: const pw.FlexColumnWidth(1), // الرقم (Number)
          3: const pw.FlexColumnWidth(1.5), // اسم المنتج (Product Name)
          4: const pw.FlexColumnWidth(0.8), // عدد المنتج (Product Count)
          5: const pw.FlexColumnWidth(0.8), // الوحدة (Unit)
          6: const pw.FlexColumnWidth(0.8), // السعر (Price)
          7: const pw.FlexColumnWidth(0.8), // الاجمالي (Total)
          8: const pw.FlexColumnWidth(1.2), // الوصف (Description)
          9: const pw.FlexColumnWidth(0.8), // المدفوع (Paid)
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildTableCell(ArabicHelper.reshapedText('م'), isHeader: true),
              _buildTableCell(
                ArabicHelper.reshapedText('التاريخ'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('الرقم'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('اسم المنتج'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('عدد المنتج'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('الوحدة'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('السعر'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('الاجمالي'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('الوصف'),
                isHeader: true,
              ),
              _buildTableCell(
                ArabicHelper.reshapedText('المدفوع'),
                isHeader: true,
              ),
            ],
          ),
          // Data rows
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final tx = entry.value;
            return pw.TableRow(
              children: [
                _buildTableCell((index + 1).toString()),
                _buildTableCell(
                  DateFormat(
                    'yyyy/MM/dd',
                  ).format(tx.transaction.transaction.date),
                ),
                _buildTableCell(tx.transaction.transaction.receiptNumber ?? ''),
                _buildTableCell(
                  tx.invoiceItems.isNotEmpty
                      ? ArabicHelper.reshapedText(
                          tx.invoiceItems.first.product?.name ??
                              'منتج غير معروف',
                        )
                      : ArabicHelper.reshapedText(
                          tx.transaction.transaction.description,
                        ),
                ),
                _buildTableCell(
                  tx.invoiceItems.isNotEmpty
                      ? tx.invoiceItems.first.invoiceItem.quantity.toString()
                      : '1',
                ),
                _buildTableCell(
                  tx.invoiceItems.isNotEmpty
                      ? ArabicHelper.reshapedText(
                          tx.invoiceItems.first.product?.unit ?? 'قطعة',
                        )
                      : ArabicHelper.reshapedText('قطعة'),
                ),
                _buildTableCell(
                  tx.invoiceItems.isNotEmpty
                      ? ArabicHelper.reshapedText(
                          _formatCurrency(
                            tx.invoiceItems.first.invoiceItem.price,
                          ),
                        )
                      : ArabicHelper.reshapedText('0.00'),
                ),
                _buildTableCell(
                  tx.invoiceItems.isNotEmpty
                      ? ArabicHelper.reshapedText(
                          _formatCurrency(
                            tx.invoiceItems.first.invoiceItem.price *
                                tx.invoiceItems.first.invoiceItem.quantity,
                          ),
                        )
                      : ArabicHelper.reshapedText(_formatCurrency(tx.total)),
                ),
                _buildTableCell(
                  ArabicHelper.reshapedText(
                    tx.transaction.transaction.description.isNotEmpty
                        ? tx.transaction.transaction.description
                        : 'بيع منتجات',
                  ),
                ),
                _buildTableCell(
                  tx.paidAmount > 0
                      ? ArabicHelper.reshapedText(
                          _formatCurrency(tx.paidAmount),
                        )
                      : ArabicHelper.reshapedText('0.00'),
                ),
              ],
            );
          }),
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

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                ArabicHelper.reshapedText('Developed by MO2'),
                style: _getTextStyle(fontSize: 8, color: PdfColors.grey600),
                textDirection: pw.TextDirection.ltr,
              ),
              pw.Text(
                ArabicHelper.reshapedText(
                  'صفحة ${context.pageNumber}/${context.pagesCount}',
                ),
                style: _getTextStyle(fontSize: 8, color: PdfColors.grey600),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              ArabicHelper.reshapedText(
                DateFormat(
                  'EEEE، dd MMMM yyyy hh:mm a',
                  'ar',
                ).format(DateTime.now()),
              ),
              style: _getTextStyle(fontSize: 8, color: PdfColors.grey500),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_EG',
      symbol: '',
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
    required InvoiceDao invoiceDao,
    required CustomerDao customerDao, // Added
    String branchName = 'الفرع الرئيسي المصنع',
    Printer? printer,
  }) async {
    final pdfData = await generateAccountStatement(
      entityName: entityName,
      entityType: entityType,
      entityId: entityId,
      fromDate: fromDate,
      toDate: toDate,
      ledgerDao: ledgerDao,
      invoiceDao: invoiceDao,
      customerDao: customerDao, // Passed
      branchName: branchName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdfData,
      name: 'Account Statement - $entityName',
      format: PdfPageFormat.a4,
    );
  }
}

class EnhancedTransaction {
  final int serialNumber;
  final LedgerTransactionWithBalance transaction;
  final List<InvoiceItemWithProduct> invoiceItems;
  final double discount;
  final double total;
  final double westernAmount;
  final double paidAmount;
  final double expenses;
  final String notes;

  EnhancedTransaction({
    required this.serialNumber,
    required this.transaction,
    required this.invoiceItems,
    required this.discount,
    required this.total,
    required this.westernAmount,
    required this.paidAmount,
    required this.expenses,
    required this.notes,
  });
}

class InvoiceItemWithProduct {
  final InvoiceItem invoiceItem;
  final Product? product;

  InvoiceItemWithProduct({required this.invoiceItem, required this.product});
}
