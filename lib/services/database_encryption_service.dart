import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

class DatabaseEncryptionService {
  static final _key = encrypt_pkg.Key.fromUtf8(
    'POS2026-DB-ENCRYPTION-32-CHARS!!', // Exactly 32 characters
  );
  static final _iv = encrypt_pkg.IV.fromLength(16);
  static final _encrypter = encrypt_pkg.Encrypter(
    encrypt_pkg.AES(_key, mode: encrypt_pkg.AESMode.cbc),
  );

  /// Encrypt sensitive data
  static String encryptData(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt data
  static String decryptData(String encryptedText) {
    try {
      final encrypted = encrypt_pkg.Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Encrypt JSON object
  static String encryptJson(Map<String, dynamic> jsonData) {
    final jsonString = jsonEncode(jsonData);
    return encryptData(jsonString);
  }

  /// Decrypt to JSON
  static Map<String, dynamic> decryptJson(String encryptedText) {
    final decrypted = decryptData(encryptedText);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }
}
