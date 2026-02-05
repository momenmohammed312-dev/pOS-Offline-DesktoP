import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/license_config.dart';
import '../models/license_model.dart';
import 'hardware_fingerprint_service.dart';
import 'anti_tamper_service.dart';

class LicenseManager {
  static const String _licenseKey = 'app_license_key';
  static const String _deviceIdKey = 'device_fingerprint';
  static const String _activationDateKey = 'activation_date';

  /// Generate a license key (ADMIN ONLY - Use separate tool)
  String generateLicenseKey({
    required String deviceFingerprint,
    required DateTime expiryDate,
    required List<String> features,
    required int maxUsers,
    required String licenseType,
  }) {
    final licenseData = {
      'device': deviceFingerprint,
      'expiry': expiryDate.toIso8601String(),
      'features': features,
      'max_users': maxUsers,
      'license_type': licenseType,
      'created': DateTime.now().toIso8601String(),
      'version': LicenseConfig.appVersion,
    };

    final jsonString = jsonEncode(licenseData);
    final bytes = utf8.encode(jsonString);

    // Encode with Base64
    final encoded = base64.encode(bytes);

    // Create HMAC signature
    final hmacBytes = utf8.encode(LicenseConfig.secretKey);
    final hmac = Hmac(sha256, hmacBytes);
    final signature = hmac.convert(utf8.encode(encoded));

    // Return: BASE64_PAYLOAD.SIGNATURE
    return '$encoded.${signature.toString()}';
  }

  /// Validate license key
  Future<LicenseValidationResult> validateLicense(String licenseKey) async {
    try {
      // Split license key
      final parts = licenseKey.split('.');
      if (parts.length != 2) {
        return LicenseValidationResult.invalid('Invalid license format');
      }

      final encoded = parts[0];
      final providedSignature = parts[1];

      // Verify signature
      final hmacBytes = utf8.encode(LicenseConfig.secretKey);
      final hmac = Hmac(sha256, hmacBytes);
      final calculatedSignature = hmac.convert(utf8.encode(encoded));

      if (calculatedSignature.toString() != providedSignature) {
        return LicenseValidationResult.invalid(
          'License signature verification failed',
        );
      }

      // Decode payload
      final jsonString = utf8.decode(base64.decode(encoded));
      final licenseData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Verify device fingerprint
      final storedFingerprint = licenseData['device'] as String?;
      if (storedFingerprint == null) {
        return LicenseValidationResult.invalid(
          'Invalid license format: missing device fingerprint',
        );
      }

      final isDeviceValid = await HardwareFingerprintService.verifyFingerprint(
        storedFingerprint,
      );

      if (!isDeviceValid) {
        return LicenseValidationResult.invalid(
          'License not valid for this device',
        );
      }

      // Check expiry
      final expiryString = licenseData['expires'] as String?;
      if (expiryString == null) {
        return LicenseValidationResult.invalid(
          'Invalid license format: missing expiry date',
        );
      }

      final expiryDate = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiryDate)) {
        return LicenseValidationResult.invalid('License has expired');
      }

      // Create license model
      final license = LicenseModel(
        licenseKey: licenseKey,
        deviceFingerprint: storedFingerprint,
        licenseType: licenseData['license_type'] as String? ?? 'unknown',
        maxUsers: licenseData['max_users'] as int? ?? 1,
        features: List<String>.from(licenseData['features'] as List? ?? []),
        createdAt: DateTime.parse(
          licenseData['created'] as String? ?? DateTime.now().toIso8601String(),
        ),
        expiresAt: expiryDate,
      );

      // Save license locally
      await _saveLicense(license);

      return LicenseValidationResult.valid(license);
    } catch (e) {
      return LicenseValidationResult.invalid('Error validating license: $e');
    }
  }

  /// Save validated license
  Future<void> _saveLicense(LicenseModel license) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseKey, license.licenseKey);
    await prefs.setString(_deviceIdKey, license.deviceFingerprint);
    await prefs.setString(_activationDateKey, DateTime.now().toIso8601String());
    await prefs.setString('license_data', jsonEncode(license.toJson()));
  }

  /// Check if valid license exists
  Future<bool> isLicenseValid() async {
    // STEP 1: Check for clock tampering FIRST
    final isTampered = await AntiTamperService.detectClockTampering();
    if (isTampered) {
      print('❌ License invalid: Clock tampering detected');
      return false;
    }

    // STEP 2: Normal license checks
    final license = await getCurrentLicense();
    if (license == null) return false;

    // Verify not expired
    if (license.isExpired) return false;

    // Verify device
    final isDeviceValid = await HardwareFingerprintService.verifyFingerprint(
      license.deviceFingerprint,
    );
    if (!isDeviceValid) return false;

    return true;
  }

  /// Get current license
  Future<LicenseModel?> getCurrentLicense() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final licenseDataStr = prefs.getString('license_data');
      if (licenseDataStr == null) return null;

      final licenseData = jsonDecode(licenseDataStr) as Map<String, dynamic>;
      return LicenseModel.fromJson(licenseData);
    } catch (e) {
      debugPrint('Error getting current license: $e');
      return null;
    }
  }

  /// Deactivate license
  Future<void> deactivateLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseKey);
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_activationDateKey);
    await prefs.remove('license_data');
  }

  /// Check if feature is enabled
  Future<bool> isFeatureEnabled(String feature) async {
    final license = await getCurrentLicense();
    if (license == null) return false;
    return license.hasFeature(feature);
  }
}
