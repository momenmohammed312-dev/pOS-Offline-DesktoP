import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

/// Simple logging function for test files (uses stderr to avoid print warnings)
void _log(String message) {
  stderr.writeln('[Font Fix Test] $message');
}

/// Test to verify correct font loading method
void main() async {
  _log('Testing correct font loading method...');

  try {
    // Method 1: Current method (may have issues)
    _log(
      'Testing current method (rootBundle.load + buffer.asUint8List + asByteData)...',
    );
    pw.Font? font1;
    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      final bytes = fontData.buffer.asUint8List();
      font1 = pw.Font.ttf(
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      // ignore: unnecessary_null_comparison
      _log('✅ Current method loaded font: ${font1 != null}');
    } catch (e) {
      _log('❌ Current method failed: $e');
    }

    // Method 2: Direct method (recommended)
    _log('Testing direct method (rootBundle.load + direct buffer)...');
    pw.Font? font2;
    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      font2 = pw.Font.ttf(fontData.buffer.asByteData());
      // ignore: unnecessary_null_comparison
      _log('✅ Direct method loaded font: ${font2 != null}');
    } catch (e) {
      _log('❌ Direct method failed: $e');
    }

    // Create test PDF with both fonts
    if (font1 != null || font2 != null) {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'اختبار الخط العربي - Font Loading Method Test',
                  style: pw.TextStyle(
                    font: font2 ?? font1!,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 30),

                // Test with font1 (current method)
                if (font1 != null) ...[
                  pw.Text(
                    'طريقة الحالية (buffer.asUint8List): اختبار الخط العربي',
                    style: pw.TextStyle(font: font1, fontSize: 16),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Test with font2 (direct method)
                if (font2 != null) ...[
                  pw.Text(
                    'طريقة المباشرة (direct buffer): اختبار الخط العربي',
                    style: pw.TextStyle(font: font2, fontSize: 16),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Test mixed content
                if (font2 != null) ...[
                  pw.Text(
                    'العربي Mixed English / الرموز: / - : © ® ™ # @ % & *',
                    style: pw.TextStyle(
                      font: font2,
                      fontFallback: [pw.Font.helvetica()],
                      fontSize: 14,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Save PDF
      final pdfBytes = await pdf.save();
      final file = File('font_loading_method_test.pdf');
      await file.writeAsBytes(pdfBytes);

      _log('✅ Font loading method test completed!');
      _log('📄 PDF saved as: font_loading_method_test.pdf');
      _log('🔍 Compare the two methods in the PDF');
    }
  } catch (e, stackTrace) {
    _log('❌ Font loading method test failed: $e');
    _log('Stack trace: $stackTrace');
  }
}
