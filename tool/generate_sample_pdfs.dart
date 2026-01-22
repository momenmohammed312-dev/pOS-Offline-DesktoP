import 'package:pos_offline_desktop/core/services/pdf_test_helper.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  await generateSamplePdfsTo('build/sample_pdfs');
  if (kDebugMode) {
    print('Generated PDFs in build/sample_pdfs');
  }
}
