import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

/// Simple logging function for test files (uses stderr to avoid print warnings)
void _log(String message) {
  stderr.writeln('[Font Test] $message');
}

/// Test script to verify font implementation with mixed content
void main() async {
  _log('Testing font implementation with mixed content...');

  try {
    // Use built-in fonts only (no Flutter dependencies)
    final arabicFont = pw.Font.times(); // Fallback for Arabic
    final arabicBoldFont = pw.Font.timesBold();
    final latinFont = pw.Font.times(); // Primary for Latin
    final latinBoldFont = pw.Font.timesBold();

    // Create test PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Test mixed content with font fallback
              pw.Text(
                'نص عربي / English / 123 / : ©',
                style: pw.TextStyle(
                  font:
                      latinFont, // Use Latin font as primary for mixed content
                  fontFallback: [
                    arabicFont,
                    pw.Font.times(),
                  ], // Arabic as fallback
                  fontSize: 16,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Bold نص عربي / Bold English / 456 / - : ©',
                style: pw.TextStyle(
                  font:
                      latinBoldFont, // Use Latin bold font as primary for mixed content
                  fontFallback: [
                    arabicBoldFont,
                    pw.Font.timesBold(),
                  ], // Arabic as fallback
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 20),

              // Test symbols and special characters
              pw.Text(
                'Test symbols and characters',
                style: pw.TextStyle(
                  font: latinFont,
                  fontFallback: [pw.Font.times()], // Built-in fonts as fallback
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 20),

              // Test numbers and dates
              pw.Text(
                'Invoice #INV-2024-001 / Date: 2024/01/15 / Total: \$1,234.56',
                style: pw.TextStyle(
                  font: latinFont,
                  fontFallback: [pw.Font.times()],
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 20),

              // Test Arabic with numbers and symbols
              pw.Text(
                'الفاتورة رقم: INV-2024-001 / التاريخ: 15/01/2024 / الإجمالي: 1,234.56 ج.م',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [latinFont, pw.Font.times()],
                  fontSize: 12,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final pdfBytes = await pdf.save();
    final file = File('test_font_implementation.pdf');
    await file.writeAsBytes(pdfBytes);

    _log('✅ Font implementation test completed successfully!');
    _log('📄 PDF saved as: test_font_implementation.pdf');
    _log('🔍 Please check the PDF to verify:');
    _log('   • Arabic text renders correctly with RTL direction');
    _log('   • English text renders correctly');
    _log('   • Numbers and symbols render correctly');
    _log('   • No "Unable to find a font to draw" messages in console');
  } catch (e, stackTrace) {
    _log('❌ Font implementation test failed: $e');
    _log('Stack trace: $stackTrace');
  }
}
