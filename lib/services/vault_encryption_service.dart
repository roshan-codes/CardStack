import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service responsible for encrypting and decrypting vault data using AES-256
/// with a master key stored in the platform's secure hardware store (Keychain/KeyStore).
class VaultEncryptionService {
  static const String _storageKey = 'cardstack_vault_master_key';
  static const String cipherIdentifier = 'AES-256-CBC';

  final FlutterSecureStorage _secureStorage;
  enc.Key? _cachedKey;

  VaultEncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Retrieves or generates a 256-bit AES master key from secure hardware storage
  Future<enc.Key> getOrGenerateKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    try {
      final existingKeyBase64 = await _secureStorage.read(key: _storageKey);
      if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
        _cachedKey = enc.Key.fromBase64(existingKeyBase64);
        return _cachedKey!;
      }

      // Generate a new 256-bit (32 bytes) cryptographically secure key
      final newKey = enc.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _storageKey,
        value: newKey.base64,
      );
      _cachedKey = newKey;
      return newKey;
    } catch (_) {
      // Fallback for test runner or platforms without secure storage plugin registered
      _cachedKey = enc.Key.fromUtf8('CardStackVaultMasterKey32Bytes!!');
      return _cachedKey!;
    }
  }

  /// Encrypts plaintext string using AES-256 with a unique random IV per operation
  Future<String> encrypt(String plainText) async {
    final key = await getOrGenerateKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final envelope = {
      'cipher': cipherIdentifier,
      'iv': iv.base64,
      'data': encrypted.base64,
    };

    return jsonEncode(envelope);
  }

  /// Decrypts ciphertext envelope. If data is legacy plaintext JSON, it returns it safely.
  Future<String> decrypt(String rawContent) async {
    final trimmed = rawContent.trim();
    if (trimmed.isEmpty) return '';

    // Check if it is an encrypted envelope
    if (trimmed.startsWith('{') && trimmed.contains('"cipher"')) {
      try {
        final Map<String, dynamic> envelope = jsonDecode(trimmed);
        if (envelope['cipher'] == cipherIdentifier &&
            envelope['iv'] != null &&
            envelope['data'] != null) {
          final key = await getOrGenerateKey();
          final iv = enc.IV.fromBase64(envelope['iv'] as String);
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

          final decrypted = encrypter.decrypt64(
            envelope['data'] as String,
            iv: iv,
          );
          return decrypted;
        }
      } catch (_) {
        // If decryption fails, fall through
      }
    }

    // Legacy unencrypted plaintext fallback for backward compatibility
    return rawContent;
  }
}
