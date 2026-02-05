class HardwareFingerprintService {
  /// Generate unique device fingerprint
  static Future<String> generateFingerprint() async {
    // For testing purposes, return a fixed device ID
    // In production, this should use actual hardware fingerprinting
    return 'test-device-123';
  }

  /// Verify if current device matches fingerprint
  static Future<bool> verifyFingerprint(String storedFingerprint) async {
    final currentFingerprint = await generateFingerprint();
    return currentFingerprint == storedFingerprint;
  }
}
