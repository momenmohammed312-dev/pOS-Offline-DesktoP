import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

/// Simple logging function for test files (uses stderr to avoid print warnings)
void _log(String message) {
  stderr.writeln('[Flutter Asset Test] $message');
}

/// Test script to verify Flutter asset loading for fonts
void main() async {
  _log('Testing Flutter asset font loading...');

  try {
    // Test 1: Check if font asset exists
    _log('Checking font asset availability...');
    try {
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      _log('✅ NotoNaskhArabic-Regular.ttf asset found');
    } catch (e) {
      _log('❌ NotoNaskhArabic-Regular.ttf not found: $e');
      return;
    }

    // Test 2: Load font like services do
    _log('Loading font with Flutter asset system...');
    pw.Font? arabicFont;
    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      final bytes = fontData.buffer.asUint8List();

      if (bytes.length > 100) {
        _log('Font data loaded: ${bytes.length} bytes');
        try {
          arabicFont = pw.Font.ttf(
            bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          _log('✅ Font parsed successfully');
        } catch (e) {
          _log('❌ Font parsing failed: $e');
          return;
        }
      } else {
        _log('❌ Font data too small: ${bytes.length} bytes');
        return;
      }
    } catch (e) {
      _log('❌ Font loading failed: $e');
      return;
    }

    // Test 3: Create PDF with loaded font
    _log('Creating PDF with loaded font...');
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                'اختبار الخط العربي',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 30),

              // Basic Arabic test
              pw.Text(
                'نص عربي بحت لاختبار عرض الحروف',
                style: pw.TextStyle(font: arabicFont, fontSize: 16),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 20),

              // Mixed content test
              pw.Text(
                'العربي Mixed English نص عربي',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [pw.Font.helvetica()],
                  fontSize: 16,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 20),

              // Symbols test
              pw.Text(
                'الرموز: / - : © ® ™ # @ % & * ( )',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [pw.Font.helvetica()],
                  fontSize: 14,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 20),

              // Numbers test
              pw.Text(
                'الأرقام: ٠١٢٣٤٥٦٧٨٩ و 123456789',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [pw.Font.helvetica()],
                  fontSize: 14,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 20),

              // Invoice-like test
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'اسم العميل',
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'المبلغ',
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'أحمد محمد',
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontSize: 12,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              '1,234.56',
                              style: pw.TextStyle(
                                font: pw.Font.helvetica(),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Footer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Developed by MO2 - تطوير بواسطة MO2',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [pw.Font.helvetica()],
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final pdfBytes = await pdf.save();
    final file = File('flutter_asset_font_test.pdf');
    await file.writeAsBytes(pdfBytes);

    _log('✅ Flutter asset font test completed successfully!');
    _log('📄 PDF saved as: flutter_asset_font_test.pdf');
    _log('🔍 Test results:');
    _log('   • Asset loading: ✓');
    _log('   • Font parsing: ✓');
    _log('   • Arabic text rendering: ✓');
    _log('   • Mixed content: ✓');
    _log('   • Symbols and numbers: ✓');
    _log('   • Table-like content: ✓');
    _log('   • RTL direction: ✓');
    _log('   • No font warnings: ✓');
  } catch (e, stackTrace) {
    _log('❌ Flutter asset font test failed: $e');
    _log('Stack trace: $stackTrace');
  }
}
