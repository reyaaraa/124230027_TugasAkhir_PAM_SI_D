// lib/services/secure_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

/// SecureStore
/// - Menyimpan kunci/secret secara terenkripsi menggunakan flutter_secure_storage
/// - Kita menggunakan AES (encrypt package) untuk enkripsi tambahan sebelum menyimpan.
/// - NOTE: kunci AES statis di code hanya untuk demo. Untuk produksi, gunakan
///   key management yang lebih aman (keystore, server-side, atau mendapat input user).
class SecureStore {
  static final _storage = const FlutterSecureStorage();

  // WARNING: untuk demo. di produksi jangan hardcode secret key,
  // gunakan keystore/platform-specific secure key derivation.
  static final _aesKey = Key.fromUtf8(
    'paruguard_demo_32bytes_secretkey', // Corrected to 32 characters
  ); // 32 chars/bytes for AES-256

  static final _encrypter = Encrypter(AES(_aesKey, mode: AESMode.cbc));

  /// Write value (encrypted) into secure storage
  static Future<void> writeEncrypted(String key, String value) async {
    final iv = IV.fromLength(16); // IV acak untuk setiap enkripsi
    final encrypted = _encrypter.encrypt(value, iv: iv);

    // Gabungkan IV dan ciphertext, pisahkan dengan titik dua.
    // Format: iv_base64:ciphertext_base64
    final combined = '${iv.base64}:${encrypted.base64}';
    await _storage.write(key: key, value: combined);
  }

  /// Read and decrypt value
  static Future<String?> readEncrypted(String key) async {
    final combined = await _storage.read(key: key);
    if (combined == null || !combined.contains(':')) return null;

    // Pisahkan kembali IV dan ciphertext
    final parts = combined.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    // Dekripsi menggunakan IV yang benar
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  /// Delete key
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> deleteEncrypted(String s) async {}
}
