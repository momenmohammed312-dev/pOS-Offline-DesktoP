import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/core/services/pdf_test_helper.dart';

void main() {
  test('generate sample PDFs via helper creates files', () async {
    final outDir = Directory('build/sample_pdfs_test');

    if (outDir.existsSync()) {
      try {
        outDir.deleteSync(recursive: true);
      } catch (_) {}
    }

    await generateSamplePdfsTo(outDir.path);

    final a4 = File('${outDir.path}${Platform.pathSeparator}sample_a4.pdf');
    final roll = File('${outDir.path}${Platform.pathSeparator}sample_roll80.pdf');

    expect(a4.existsSync(), isTrue, reason: 'A4 PDF should exist');
    expect(roll.existsSync(), isTrue, reason: 'Roll80 PDF should exist');

    expect(a4.lengthSync() > 100, isTrue, reason: 'A4 PDF should be non-empty');
    expect(roll.lengthSync() > 100, isTrue, reason: 'Roll80 PDF should be non-empty');
  }, timeout: Timeout(Duration(minutes: 2)));
}
