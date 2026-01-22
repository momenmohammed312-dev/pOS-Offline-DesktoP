import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

/// High-Fidelity PDF Generation Service
/// Replicates invoice layout exactly with Arabic support
class PdfInvoiceService {
  static Future<Uint8List> generateInvoicePdf(
    Invoice invoice,
    List<InvoiceItem> items, {
    String customerName = 'عميل',
    String branchName = 'الفرع الرئيسي المصنع',
  }) async {
    final pdf = pw.Document();

    try {
      // Load Arabic Font with fallback
      pw.Font? ttf;
      pw.Font? boldTtf;

      try {
        final fontData = await rootBundle.load(
          "assets/fonts/Cairo-Regular.ttf",
        );
        ttf = pw.Font.ttf(fontData);
      } catch (e) {
        // Fallback to default font if Cairo font not found
        // Warning: Cairo-Regular font not found, using default font
      }

      try {
        final boldFontData = await rootBundle.load(
          "assets/fonts/Cairo-Bold.ttf",
        );
        boldTtf = pw.Font.ttf(boldFontData);
      } catch (e) {
        // Fallback to default font if Cairo-Bold font not found
        // Warning: Cairo-Bold font not found, using default font
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          theme: pw.ThemeData.withFont(
            base: ttf ?? pw.Font.helvetica(),
            bold: boldTtf ?? pw.Font.helveticaBold(),
          ),
          textDirection: pw.TextDirection.rtl, // CRITICAL for Arabic
          build: (pw.Context context) {
            return [
              _buildHeader(
                branchName,
                ttf ?? pw.Font.helvetica(),
                boldTtf ?? pw.Font.helveticaBold(),
              ),
              pw.SizedBox(height: 16),
              _buildInvoiceInfo(
                invoice,
                ttf ?? pw.Font.helvetica(),
                boldTtf ?? pw.Font.helveticaBold(),
              ),
              pw.SizedBox(height: 8),
              _buildCustomerInfo(
                customerName,
                invoice,
                ttf ?? pw.Font.helvetica(),
                boldTtf ?? pw.Font.helveticaBold(),
              ),
              pw.SizedBox(height: 16),
              _buildTable(
                items,
                ttf ?? pw.Font.helvetica(),
                boldTtf ?? pw.Font.helveticaBold(),
              ),
              pw.SizedBox(height: 16),
              _buildFooter(
                invoice,
                items,
                ttf ?? pw.Font.helvetica(),
                boldTtf ?? pw.Font.helveticaBold(),
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw Exception('فشل في إنشاء PDF: $e');
    }
  }

  /// Build Header with Company Info
  static pw.Widget _buildHeader(
    String branchName,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Company Info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'شركة المثالية للتجارة',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                branchName,
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                'تليفون: 01234567890',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'الرقم الضريبي: 123456789',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
          // Right side - Logo placeholder
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Center(
              child: pw.Text(
                'LOGO',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Invoice Information
  static pw.Widget _buildInvoiceInfo(
    Invoice invoice,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final invoiceType = invoice.paymentMethod == 'cash'
        ? 'فاتورة مبيعات'
        : 'فاتورة آجلة';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            invoiceType,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'رقم الفاتورة: ${invoice.invoiceNumber ?? invoice.id}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                'التاريخ: ${_formatDate(invoice.date)}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Customer Information
  static pw.Widget _buildCustomerInfo(
    String customerName,
    Invoice invoice,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'اسم العميل:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  customerName,
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                if (invoice.customerAddress != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.customerAddress!,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'طريقة الدفع:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _getPaymentMethodLabel(invoice.paymentMethod),
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Products Table - Exact Layout Replication
  static pw.Widget _buildTable(
    List<InvoiceItem> items,
    pw.Font font,
    pw.Font boldFont,
  ) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        child: pw.Center(
          child: pw.Text(
            'لا توجد أصناف في هذه الفاتورة',
            style: pw.TextStyle(font: font, fontSize: 14),
          ),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(
        width: 1,
        color: PdfColors.black,
      ), // The black grid lines
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
        font: boldFont,
      ),
      cellStyle: pw.TextStyle(fontSize: 11, font: font),
      headers: [
        'م',
        'الصنف',
        'الكمية',
        'السعر',
        'الإجمالي',
      ], // Seq, Item, Qty, Price, Total
      data: List.generate(items.length, (index) {
        final item = items[index];
        final total = item.quantity * item.price;
        return [
          '${index + 1}',
          'منتج #${item.productId}', // Since we don't have product name directly
          item.quantity.toString(),
          item.price.toStringAsFixed(2),
          total.toStringAsFixed(2),
        ];
      }),
      cellAlignment: pw.Alignment.center,
      headerAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // م
        1: const pw.FlexColumnWidth(3), // الصنف
        2: const pw.FixedColumnWidth(50), // الكمية
        3: const pw.FixedColumnWidth(60), // السعر
        4: const pw.FixedColumnWidth(60), // الإجمالي
      },
    );
  }

  /// Build Footer with Totals
  static pw.Widget _buildFooter(
    Invoice invoice,
    List<InvoiceItem> items,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final totalAmount = invoice.totalAmount;
    final paidAmount = invoice.paidAmount;
    final remaining = totalAmount - paidAmount;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          // Totals Table
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Column(
              children: [
                _buildTotalRow(
                  'الإجمالي',
                  totalAmount.toStringAsFixed(2),
                  font,
                  boldFont,
                ),
                pw.Divider(color: PdfColors.black),
                _buildTotalRow(
                  'المدفوع',
                  paidAmount.toStringAsFixed(2),
                  font,
                  boldFont,
                ),
                pw.Divider(color: PdfColors.black),
                _buildTotalRow(
                  'المتبقي',
                  remaining.toStringAsFixed(2),
                  font,
                  boldFont,
                  isBold: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Notes
          if (invoice.customerContact != null) ...[
            pw.Text(
              'ملاحظات: ${invoice.customerContact}',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ],
          pw.SizedBox(height: 8),
          // Footer text
          pw.Center(
            child: pw.Text(
              'شكراً لتعاملكم معنا',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 14,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for Total Rows
  static pw.Widget _buildTotalRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont, {
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isBold ? boldFont : font,
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: isBold ? boldFont : font,
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Export PDF to File
  static Future<File> exportPdf(
    Invoice invoice,
    List<InvoiceItem> items, {
    String customerName = 'عميل',
  }) async {
    try {
      final pdfBytes = await generateInvoicePdf(
        invoice,
        items,
        customerName: customerName,
      );

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'invoice_${invoice.invoiceNumber ?? invoice.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save PDF
      return await file.writeAsBytes(pdfBytes);
    } catch (e) {
      throw Exception('فشل في تصدير PDF: $e');
    }
  }

  /// Helper Methods
  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  static String _getPaymentMethodLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'credit':
        return 'آجل';
      case 'visa':
        return 'فيزا';
      case 'mastercard':
        return 'ماستر كارد';
      case 'bank':
        return 'تحويل بنكي';
      default:
        return method ?? 'غير محدد';
    }
  }
}
