import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Local passphrase-protected backup wrapper (AES-256 CBC).
///
/// Never uploaded by Textara. Passphrases are not stored — only the user holds them.
class EncryptedBackup {
  static const magic = 'TEXTARA_ENC_V1';

  /// Encrypts UTF-8 plaintext with a passphrase. Returns a portable string payload.
  static String seal(String plaintext, String passphrase) {
    if (passphrase.trim().length < 8) {
      throw ArgumentError('Passphrase must be at least 8 characters.');
    }
    final key = _keyFromPassphrase(passphrase);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final payload = {
      'magic': magic,
      'iv': base64Encode(iv.bytes),
      'data': encrypted.base64,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Decrypts a payload produced by [seal].
  static String open(String sealed, String passphrase) {
    final json = jsonDecode(sealed) as Map<String, dynamic>;
    if (json['magic'] != magic) {
      throw const FormatException('Not a Textara encrypted backup.');
    }
    final key = _keyFromPassphrase(passphrase);
    final iv = enc.IV.fromBase64(json['iv'] as String);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(json['data'] as String, iv: iv);
  }

  static enc.Key _keyFromPassphrase(String passphrase) {
    // Stretch passphrase into 32 bytes via SHA-256 (local-only convenience).
    final digest = sha256.convert(utf8.encode(passphrase));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }
}
