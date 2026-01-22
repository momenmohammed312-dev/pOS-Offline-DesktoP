import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  // Load fonts from assets
  final arabicFontData = await rootBundle.load(
    'assets/fonts/NotoNaskhArabic-Regular.ttf',
  );
  final latinFontData = await rootBundle.load(
    'assets/fonts/Roboto-Regular.ttf',
  );

  final arabicFont = pw.Font.ttf(arabicFontData);
  final latinFont = pw.Font.ttf(latinFontData);

  // Create PDF document
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // RTL Arabic-heavy line with fallback
            pw.Text(
              'فاتورة دفع رقم ١٢٣\nINV/Payment #123',
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [latinFont],
                fontSize: 16,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 20),
            // LTR English-heavy line with fallback
            pw.Text(
              'Invoice Payment #123\nفاتورة دفع رقم ١٢٣',
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [latinFont],
                fontSize: 16,
              ),
              textDirection: pw.TextDirection.ltr,
            ),
          ],
        );
      },
    ),
  );

  // Save PDF to specified path
  final file = File(r'G:\flutter\Documents\customer_statement_fixed.pdf');
  await file.writeAsBytes(await pdf.save());

  stderr.writeln('PDF saved to: ${file.path}');
}
