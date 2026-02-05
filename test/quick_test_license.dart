import 'dart:io';
import 'dart:convert';

/// Quick Test License Generator
/// تستخدم لإنشاء تراخيص اختبار سريعة لتجربة النظام
void main() async {
  print('=== POS Quick License Generator ===');
  print('إنشاء تراخيص اختبار سريعة...\n');

  // Device ID للاختبار (استخدم الـ Device ID الحقيقي من شاشة التفعيل)
  const testDeviceId = '1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF';
  
  // إنشاء ترخيص أساسي (يوم واحد للاختبار السريع)
  final basicLicense = _generateLicense(
    deviceId: testDeviceId,
    licenseType: 'Basic',
    duration: 'Daily',
    maxUsers: 1,
    expiryDays: 1,
    features: ['products', 'sales', 'reports'],
  );
  
  // إنشاء ترخيص قياسي (أسبوع واحد للاختبار المتوسط)
  final standardLicense = _generateLicense(
    deviceId: testDeviceId,
    licenseType: 'Standard',
    duration: 'Weekly',
    maxUsers: 3,
    expiryDays: 7,
    features: ['products', 'sales', 'reports', 'customers', 'backup'],
  );
  
  // إنشاء ترخيص احترافي (شهر واحد للاختبار الشامل)
  final professionalLicense = _generateLicense(
    deviceId: testDeviceId,
    licenseType: 'Professional',
    duration: 'Monthly',
    maxUsers: 5,
    expiryDays: 30,
    features: ['products', 'sales', 'reports', 'customers', 'suppliers', 'backup', 'purchases'],
  );

  // حفظ التراخيص في ملفات
  await _saveLicenseToFile('basic_test_license.json', basicLicense);
  await _saveLicenseToFile('standard_test_license.json', standardLicense);
  await _saveLicenseToFile('professional_test_license.json', professionalLicense);

  print('✅ تم إنشاء تراخيص الاختبار بنجاح!');
  print('\nالملفات التي تم إنشاؤها:');
  print('📄 basic_test_license.json - ترخيص أساسي (يوم واحد)');
  print('📄 standard_test_license.json - ترخيص قياسي (أسبوع واحد)');
  print('📄 professional_test_license.json - ترخيص احترافي (شهر واحد)');
  print('\n⚠️  ملاحظة: استبدل testDeviceId بالـ Device ID الحقيقي من شاشة التفعيل');
  print('\n📋 خطوات الاستخدام:');
  print('1. انسخ أي ملف ترخيص');
  print('2. الصق المحتوى في حقل License Key في التطبيق');
  print('3. اضغط على Activate License');
}

Map<String, dynamic> _generateLicense({
  required String deviceId,
  required String licenseType,
  required String duration,
  required int maxUsers,
  required int expiryDays,
  required List<String> features,
}) {
  final now = DateTime.now();
  final expiryDate = now.add(Duration(days: expiryDays));
  
  return {
    'deviceId': deviceId,
    'licenseType': licenseType,
    'duration': duration,
    'maxUsers': maxUsers,
    'issueDate': now.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'features': features,
    'signature': 'TEST_SIGNATURE_${DateTime.now().millisecondsSinceEpoch}',
    'version': '2.0.0',
  };
}

Future<void> _saveLicenseToFile(String filename, Map<String, dynamic> license) async {
  final file = File(filename);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(license),
    encoding: utf8,
  );
  print('💾 تم حفظ: $filename');
}
