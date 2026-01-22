import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show debugPrint;

/// Simple PDF font test without Flutter dependencies
void main() async {
  debugPrint('Testing PDF font fallback system...');

  try {
    // Create test PDF with built-in fonts only
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Test with Times font (built-in)
              pw.Text(
                'Test with Times font: ABC123 / INV-001 / \$123.45',
                style: pw.TextStyle(font: pw.Font.times(), fontSize: 16),
              ),
              pw.SizedBox(height: 20),

              // Test with Times Bold font (built-in)
              pw.Text(
                'Bold Times: ABC123 / INV-002 / \$678.90',
                style: pw.TextStyle(
                  font: pw.Font.timesBold(),
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Test with Courier font (built-in)
              pw.Text(
                'Courier font: ABC123 / INV-003 / 999.00',
                style: pw.TextStyle(font: pw.Font.courier(), fontSize: 16),
              ),
              pw.SizedBox(height: 20),

              // Test with Helvetica font (built-in)
              pw.Text(
                'Helvetica: ABC123 / INV-004 / 111.22',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 16),
              ),
              pw.SizedBox(height: 20),

              // Test mixed content with fallback
              pw.Text(
                'Mixed: ABC123 / INV-005 / 333.44 / Symbols',
                style: pw.TextStyle(
                  font: pw.Font.times(),
                  fontFallback: [pw.Font.helvetica(), pw.Font.courier()],
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 20),

              // Test special characters
              pw.Text(
                'Test characters and symbols',
                style: pw.TextStyle(
                  font: pw.Font.times(),
                  fontFallback: [pw.Font.helvetica()],
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final pdfBytes = await pdf.save();
    final file = File('simple_font_test.pdf');
    await file.writeAsBytes(pdfBytes);

    debugPrint('✅ Simple font test completed successfully!');
    debugPrint('📄 PDF saved as: simple_font_test.pdf');
    debugPrint(
      '🔍 This test uses only built-in fonts (Times, Helvetica, Courier)',
    );
    debugPrint('🔍 Check if Latin characters and symbols render correctly');
  } catch (e, stackTrace) {
    debugPrint('❌ Simple font test failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
