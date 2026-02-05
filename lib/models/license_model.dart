class LicenseModel {
  final String licenseKey;
  final String deviceFingerprint;
  final String licenseType;
  final int maxUsers;
  final List<String> features;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  LicenseModel({
    required this.licenseKey,
    required this.deviceFingerprint,
    required this.licenseType,
    required this.maxUsers,
    required this.features,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
  });

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      licenseKey: json['license_key'] as String? ?? '',
      deviceFingerprint: json['device_fingerprint'] as String? ?? '',
      licenseType: json['license_type'] as String? ?? 'unknown',
      maxUsers: json['max_users'] as int? ?? 1,
      features: List<String>.from(json['features'] as List? ?? []),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        json['expires_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'license_key': licenseKey,
      'device_fingerprint': deviceFingerprint,
      'license_type': licenseType,
      'max_users': maxUsers,
      'features': features,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get daysRemaining {
    final difference = expiresAt.difference(DateTime.now());
    return difference.inDays;
  }

  bool hasFeature(String feature) {
    return features.contains(feature);
  }
}

class LicenseValidationResult {
  final bool isValid;
  final String? errorMessage;
  final LicenseModel? license;

  LicenseValidationResult.valid(this.license)
    : isValid = true,
      errorMessage = null;

  LicenseValidationResult.invalid(this.errorMessage)
    : isValid = false,
      license = null;
}
