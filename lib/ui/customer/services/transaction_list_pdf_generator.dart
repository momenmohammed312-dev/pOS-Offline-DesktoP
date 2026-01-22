import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_offline_desktop/ui/customer/models/transaction_display_model.dart';

/// PDF generator that produces identical layout to the UI transaction list
/// Uses the same TransactionDisplayModel to ensure consistency
class TransactionListPdfGenerator {
  static Future<Uint8List> generateTransactionListPdf(
    List<TransactionDisplayModel> transactions,
    String customerName, {
    String fromDate = '',
    String toDate = '',
    String branchName = 'الفرع الرئيسي المصنع',
  }) async {
    final pdf = pw.Document();

    // Load Arabic fonts
    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();

    // Define colors matching the UI
    const primaryColor = PdfColors.blue;
    const textColor = PdfColors.black;
    const secondaryTextColor = PdfColors.grey700;
    const positiveColor = PdfColors.green;
    const negativeColor = PdfColors.red;
    const backgroundColor = PdfColors.white;
    const headerColor = PdfColors.grey100;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(
              customerName,
              fromDate,
              toDate,
              branchName,
              arabicBoldFont,
              arabicFont,
              primaryColor,
              textColor,
            ),

            pw.SizedBox(height: 16),

            // Table Header
            tableHeader(arabicBoldFont),

            // Transaction list
            if (transactions.isEmpty)
              _buildEmptyState(arabicFont, secondaryTextColor)
            else
              ...transactions.asMap().entries.map(
                (entry) => _buildTransactionTile(
                  entry.value,
                  arabicFont,
                  arabicBoldFont,
                  positiveColor,
                  negativeColor,
                  textColor,
                  secondaryTextColor,
                  headerColor,
                  entry.key + 1, // Pass serial number (1-based)
                ),
              ),

            // Footer
            pw.SizedBox(height: 32),
            _buildFooter(arabicFont, secondaryTextColor),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    String customerName,
    String fromDate,
    String toDate,
    String branchName,
    pw.Font boldFont,
    pw.Font regularFont,
    PdfColor primaryColor,
    PdfColor textColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Title - centered like old format
          pw.Text(
            'كشف حساب',
            style: pw.TextStyle(font: boldFont, fontSize: 20, color: textColor),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            customerName,
            style: pw.TextStyle(font: boldFont, fontSize: 16, color: textColor),
          ),
          pw.SizedBox(height: 16),

          // Date range and branch info
          if (fromDate.isNotEmpty && toDate.isNotEmpty)
            pw.Text(
              'الفترة: $fromDate - $toDate',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 12,
                color: textColor,
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            branchName,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionTile(
    TransactionDisplayModel transaction,
    pw.Font regularFont,
    pw.Font boldFont,
    PdfColor positiveColor,
    PdfColor negativeColor,
    PdfColor textColor,
    PdfColor secondaryTextColor,
    PdfColor headerColor,
    int serialNumber,
  ) {
    final isDebit = transaction.amount >= 0;

    return transactionRow(
      transaction,
      isDebit,
      regularFont,
      boldFont,
      positiveColor,
      serialNumber,
    );
  }

  /// Table Header - مطابق للصورة القديمة
  static pw.Widget tableHeader(pw.Font boldFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        color: PdfColors.grey200,
      ),
      child: pw.Row(
        children: [
          cell('م', 30, bold: true, font: boldFont), // م (مسلسل)
          cell('التاريخ', 70, bold: true, font: boldFont),
          cell('الرقم', 60, bold: true, font: boldFont),
          cell('البيان', 200, bold: true, font: boldFont),
          cell('الخصم', 50, bold: true, font: boldFont),
          cell('الإجمالي', 60, bold: true, font: boldFont),
          cell('الغربية', 60, bold: true, font: boldFont),
          cell('المدفوع', 60, bold: true, font: boldFont),
          cell('مصروفات', 60, bold: true, font: boldFont),
          cell('ملاحظات', 80, bold: true, font: boldFont),
          cell('مدين', 60, bold: true, font: boldFont),
          cell('دائن', 60, bold: true, font: boldFont),
          cell('الرصيد', 70, bold: true, font: boldFont),
        ],
      ),
    );
  }

  /// Transaction Row - مطابق للصورة القديمة بـ 13 عمود
  static pw.Widget transactionRow(
    TransactionDisplayModel transaction,
    bool isDebit,
    pw.Font regularFont,
    pw.Font boldFont,
    PdfColor positiveColor,
    int serialNumber, // Add serial number parameter
  ) {
    final amount = transaction.formattedAmount;

    // Extract receipt number with fallback logic
    String receiptNumber = transaction.receiptNumber ?? '-';

    // If no receipt number but description contains invoice info, extract it
    if (receiptNumber == '-' &&
        transaction.description != null &&
        transaction.description!.contains('فاتورة رقم')) {
      final parts = transaction.description!.split('فاتورة رقم ');
      if (parts.length > 1) {
        receiptNumber = parts[1];
      }
    }

    // Final fallback to transaction ID
    if (receiptNumber == '-') {
      receiptNumber = transaction.id;
    }

    // Prepare statement text with product details
    String statementText = '';
    if (transaction.productDetails != null &&
        transaction.productDetails!.isNotEmpty) {
      // Show product details for invoices - limit to first 2 products to fit in table
      final products = transaction.productDetails!.take(2).map((product) {
        // Extract just the product name for cleaner display
        final parts = product.split(' - ');
        return parts.isNotEmpty ? parts[0] : product;
      }).toList();

      statementText = products.join('، ');

      // Add "..." if there are more products
      if (transaction.productDetails!.length > 2) {
        statementText += '... و ${transaction.productDetails!.length - 2} أخرى';
      }
    } else if (transaction.description != null) {
      statementText = transaction.description!;
    } else {
      statementText = transaction.rightTitle;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Row(
        children: [
          // م (مسلسل)
          cell(serialNumber.toString(), 30, font: regularFont),
          // التاريخ
          cell(transaction.formattedDate, 70, font: regularFont),
          // الرقم
          cell(receiptNumber, 60, font: regularFont),
          // البيان - يظهر تفاصيل المنتجات للفواتير
          cell(
            statementText,
            200,
            align: pw.TextAlign.right, // Right align for Arabic
            font: regularFont,
          ),
          // الخصم
          cell('0', 50, font: regularFont), // Usually 0 for transactions
          // الإجمالي
          cell(amount, 60, font: boldFont),
          // الغربية
          cell('0', 60, font: regularFont), // Usually 0
          // المدفوع
          cell(isDebit ? amount : '0', 60, font: regularFont),
          // مصروفات
          cell('0', 60, font: regularFont), // Usually 0
          // ملاحظات
          cell('', 80, font: regularFont), // Empty for now
          // مدين
          cell(isDebit ? amount : '0', 60, font: regularFont),
          // دائن
          cell(isDebit ? '0' : amount, 60, font: regularFont),
          // الرصيد
          cell('', 70, font: regularFont), // Will be calculated separately
        ],
      ),
    );
  }

  /// Helper واحدة بس (مهمة)
  static pw.Widget cell(
    String text,
    double width, {
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.center,
    pw.Font? font,
  }) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide())),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
          font: font,
        ),
      ),
    );
  }

  static pw.Widget _buildEmptyState(pw.Font font, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(32),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            '📄',
            style: pw.TextStyle(font: font, fontSize: 32, color: color),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'لا توجد حركات في الفترة المحددة',
            style: pw.TextStyle(font: font, fontSize: 14, color: color),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font, PdfColor color) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(
            'Developed by MO2 (NextComm)',
            style: pw.TextStyle(font: font, fontSize: 10, color: color),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'تاريخ الطباعة: ${DateTime.now().toString().substring(0, 19)}',
            style: pw.TextStyle(font: font, fontSize: 8, color: color),
          ),
        ],
      ),
    );
  }
}

// Helper class for Google Fonts
class PdfGoogleFonts {
  static Future<pw.Font> notoSansArabicRegular() async {
    // For now, use a built-in font as placeholder
    // In production, you would load the actual font file from assets
    return pw.Font.courier();
  }

  static Future<pw.Font> notoSansArabicBold() async {
    // For now, use a built-in font as placeholder
    // In production, you would load the actual font file from assets
    return pw.Font.courierBold();
  }
}
