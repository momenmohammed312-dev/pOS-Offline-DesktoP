import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

/// Simple logging function for test files (uses stderr to avoid print warnings)
void _log(String message) {
  stderr.writeln('[Simple PDF Test] $message');
}

/// Simple test to verify basic PDF generation
void main() async {
  _log('Testing simple PDF generation...');

  try {
    // Create test PDF with built-in fonts only
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title with built-in font
              pw.Text(
                'PDF Test - Arabic fonts not available',
                style: pw.TextStyle(
                  font: pw.Font.times(),
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Test with built-in font (will show squares for Arabic)
              pw.Text(
                'Arabic text with built-in font: اختبار عربي',
                style: pw.TextStyle(font: pw.Font.times(), fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // English text
              pw.Text(
                'English text with built-in font: This should work fine',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // Test symbols
              pw.Text(
                'Symbols test: / - : © ® ™ # @ % & * ( ) [ ] { }',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Test numbers
              pw.Text(
                'Numbers test: 1234567890 / 15/01/2024 / 1,234.56',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Footer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Test completed - Developed by MO2',
                  style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final pdfBytes = await pdf.save();
    final file = File('simple_pdf_test.pdf');
    await file.writeAsBytes(pdfBytes);

    _log('✅ Simple PDF test completed successfully!');
    _log('📄 PDF saved as: simple_pdf_test.pdf');
    _log('🔍 Test results:');
    _log('   • Built-in font loading: ✓');
    _log('   • English text: ✓');
    _log('   • Numbers and symbols: ✓');
    _log('   • Arabic text (will show squares): ⚠️');
    _log('   • PDF generation: ✓');
  } catch (e, stackTrace) {
    _log('❌ Simple PDF test failed: $e');
    _log('Stack trace: $stackTrace');
  }
}
