import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generate sample A4 and roll80 PDFs into [outDirPath].
/// Creates the output directory if missing.
Future<void> generateSamplePdfsTo(String outDirPath) async {
  final outDir = Directory(outDirPath);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final regularPath = 'assets/fonts/NotoNaskhArabic-Regular.ttf';
  final boldPath = 'assets/fonts/NotoNaskhArabic-Regular.ttf';
  final regular = File(regularPath);
  final bold = File(boldPath);

  final regularBytes = regular.existsSync()
      ? await regular.readAsBytes()
      : null;
  final boldBytes = bold.existsSync() ? await bold.readAsBytes() : null;

  final docA4 = pw.Document();
  final docThermal = pw.Document();

  pw.Font? arabic;
  pw.Font? arabicBold;
  if (regularBytes != null) {
    arabic = pw.Font.ttf(regularBytes.buffer.asByteData());
  }
  if (boldBytes != null) {
    arabicBold = pw.Font.ttf(boldBytes.buffer.asByteData());
  }

  final font = arabic ?? pw.Font.helvetica();
  final bfont = arabicBold ?? font;

  docA4.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (c) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'فاتورة تجريبية',
                style: pw.TextStyle(font: bfont, fontSize: 20),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'هذا نص عربي نموذجي للاختبار.',
                style: pw.TextStyle(font: font),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['م', 'المنتج', 'كمية', 'سعر', 'المبلغ'],
                data: [
                  ['1', 'موز', '2', '10.00', '20.00'],
                  ['2', 'تفاح', '1', '15.50', '15.50'],
                ],
                headerStyle: pw.TextStyle(font: bfont),
                cellStyle: pw.TextStyle(font: font),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  docThermal.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (c) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'فاتورة رول',
                style: pw.TextStyle(font: bfont, fontSize: 16),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('منتج 1    10.00', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 8),
            pw.Text('الإجمالي: 10.00', style: pw.TextStyle(font: bfont)),
          ],
        ),
      ),
    ),
  );

  final a4Path = '${outDir.path}${Platform.pathSeparator}sample_a4.pdf';
  final rollPath = '${outDir.path}${Platform.pathSeparator}sample_roll80.pdf';

  await File(a4Path).writeAsBytes(await docA4.save());
  await File(rollPath).writeAsBytes(await docThermal.save());
}
