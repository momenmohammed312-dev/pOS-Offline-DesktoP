import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ArabicPdfTest {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;

  static Future<void> _loadFonts() async {
    if (_arabicFont == null) {
      try {
        final regularFontData = await rootBundle.load(
          'assets/fonts/NotoSansArabic-Regular.ttf',
        );
        final regBytes = regularFontData.buffer.asUint8List();
        if (regBytes.length > 100) {
          try {
            _arabicFont = pw.Font.ttf(
              regBytes.buffer.asByteData(
                regBytes.offsetInBytes,
                regBytes.lengthInBytes,
              ),
            );
          } catch (e) {
            _arabicFont = null;
          }
        }
      } catch (_) {
        _arabicFont = null;
      }

      try {
        final boldFontData = await rootBundle.load(
          'assets/fonts/NotoNaskhArabic-Regular.ttf',
        );
        final boldBytes = boldFontData.buffer.asUint8List();
        if (boldBytes.length > 100) {
          try {
            _arabicBoldFont = pw.Font.ttf(
              boldBytes.buffer.asByteData(
                boldBytes.offsetInBytes,
                boldBytes.lengthInBytes,
              ),
            );
          } catch (e) {
            _arabicBoldFont = null;
          }
        }
      } catch (_) {
        _arabicBoldFont = null;
      }
    }
  }

  static Future<void> testArabicPdf() async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'اختبار الخط العربي',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: _arabicBoldFont,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'هذا نص تجريبي باللغة العربية للتأكد من أن الخطوط تعمل بشكل صحيح في ملفات PDF',
              style: pw.TextStyle(fontSize: 16, font: _arabicFont),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 20),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'العمود الأول',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: _arabicBoldFont,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'العمود الثاني',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: _arabicBoldFont,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'بيان 1',
                          style: pw.TextStyle(font: _arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'هذا نص تجريبي في جدول',
                          style: pw.TextStyle(font: _arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
      name: 'Arabic PDF Test',
    );
  }
}
