// This is a standalone script to generate licenses
// Run with: dart run tools/license_generator.dart
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Copy these values from lib/config/license_config.dart
const String secretKey = 'POS-SaaS-2026-PROD-SECURE-K3Y-F0R-L1C3NS3!';

// License duration configurations
const Map<String, Map<String, dynamic>> licenseDurations = {
  'monthly': {'name': 'شهري', 'days': 30, 'price_multiplier': 1.0},
  'yearly': {'name': 'سنوي', 'days': 365, 'price_multiplier': 10.0},
  'lifetime': {'name': 'مدى الحياة', 'days': 36500, 'price_multiplier': 20.0},
};

void main() async {
  print('=================================');
  print('   LICENSE KEY GENERATOR');
  print('=================================\n');

  // Get device fingerprint
  stdout.write('Enter customer\'s Device ID: ');
  final deviceFingerprint = stdin.readLineSync()?.trim() ?? '';
  if (deviceFingerprint.isEmpty) {
    print('ERROR: Device ID is required!');
    exit(1);
  }

  // Select license type
  print('\nLicense Types:');
  print('1. Basic (1 user)');
  print('2. Standard (3 users)');
  print('3. Professional (5 users)');
  print('4. Enterprise (10 users)');
  print('5. Administrator (lifetime, unlimited users)');
  stdout.write('\nSelect type (1-5): ');
  final typeChoice = stdin.readLineSync()?.trim() ?? '1';

  final licenseTypes = {
    '1': {
      'name': 'basic',
      'users': 1,
      'features': ['pos', 'inventory', 'customers', 'reports'],
    },
    '2': {
      'name': 'standard',
      'users': 3,
      'features': ['pos', 'inventory', 'customers', 'suppliers', 'reports'],
    },
    '3': {
      'name': 'professional',
      'users': 5,
      'features': [
        'pos',
        'inventory',
        'customers',
        'suppliers',
        'reports',
        'accounting',
        'users',
      ],
    },
    '4': {
      'name': 'enterprise',
      'users': 10,
      'features': [
        'pos',
        'inventory',
        'customers',
        'suppliers',
        'reports',
        'accounting',
        'users',
        'backup',
        'export',
      ],
    },
    '5': {
      'name': 'admin',
      'users': 999,
      'features': [
        'pos',
        'inventory',
        'customers',
        'suppliers',
        'reports',
        'accounting',
        'users',
        'backup',
        'export',
        'admin',
      ],
      'lifetime': true,
    },
  };

  final selectedType = licenseTypes[typeChoice] ?? licenseTypes['1']!;

  // Select duration
  print('\nLicense Duration:');
  print('1. Monthly (30 days)');
  print('2. Yearly (365 days) - BEST VALUE (2 months free!)');
  print('3. Lifetime (100 years)');

  if (selectedType.containsKey('lifetime') &&
      selectedType['lifetime'] == true) {
    print('4. Administrator (lifetime - already selected)');
  }

  stdout.write('\nSelect duration (1-3): ');
  final durationChoice = stdin.readLineSync()?.trim() ?? '2';

  int days;
  String durationName;
  double priceMultiplier;

  if (selectedType.containsKey('lifetime') &&
      selectedType['lifetime'] == true) {
    days = 36500; // 100 years
    durationName = 'مدى الحياة';
    priceMultiplier = 0; // Free for admin
    print('\nAdministrator license - LIFETIME duration');
  } else {
    final selectedDuration =
        licenseDurations[durationChoice] ?? licenseDurations['yearly']!;
    days = selectedDuration['days'];
    durationName = selectedDuration['name'];
    priceMultiplier = selectedDuration['price_multiplier'];
    print('\nDuration: $durationName ($days days)');
  }

  // Generate license
  final expiryDate = DateTime.now().add(Duration(days: days));
  final licenseData = {
    'device': deviceFingerprint,
    'expiry': expiryDate.toIso8601String(),
    'features': selectedType['features'],
    'max_users': selectedType['users'],
    'license_type': selectedType['name'],
    'duration': durationName,
    'duration_days': days,
    'price_multiplier': priceMultiplier,
    'created': DateTime.now().toIso8601String(),
    'version': '2.0.0',
  };

  final jsonString = jsonEncode(licenseData);
  final bytes = utf8.encode(jsonString);
  final encoded = base64.encode(bytes);
  final hmacBytes = utf8.encode(secretKey);
  final hmac = Hmac(sha256, hmacBytes);
  final signature = hmac.convert(utf8.encode(encoded));
  final licenseKey = '$encoded.${signature.toString()}';

  // Display results
  print('\n${'=' * 60}');
  print('LICENSE GENERATED SUCCESSFULLY');
  print('=' * 60);
  print('Type: ${selectedType['name']}');
  print('Duration: $durationName');
  print('Max Users: ${selectedType['users']}');
  if (days >= 36500) {
    print('Expires: Never (lifetime license)');
  } else {
    print('Expires: ${expiryDate.toIso8601String().split('T')[0]}');
  }
  print('Features: ${(selectedType['features'] as List).join(", ")}');
  print('=' * 60);
  print('\nLICENSE KEY:');
  print(licenseKey);
  print('=' * 60);

  // Save to file
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final filename = 'license_${selectedType['name']}_$timestamp.txt';
  final file = File('licenses/$filename');
  await file.create(recursive: true);
  await file.writeAsString('''
LICENSE INFORMATION
===================
Generated: ${DateTime.now()}
Device ID: $deviceFingerprint
Type: ${selectedType['name']}
Max Users: ${selectedType['users']}
${selectedType.containsKey('lifetime') && selectedType['lifetime'] == true ? 'Duration: LIFETIME\nExpires: Never (lifetime license)' : 'Duration: $days days\nExpires: ${expiryDate.toIso8601String().split('T')[0]}'}
Features: ${(selectedType['features'] as List).join(", ")}

LICENSE KEY:
$licenseKey
''');

  print('\nLicense saved to: $filename\n');
}
