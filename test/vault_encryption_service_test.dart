import 'dart:convert';
import 'package:card_stack/data/card_repository.dart';
import 'package:card_stack/models/card_model.dart';
import 'package:card_stack/services/vault_encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultEncryptionService Tests', () {
    late VaultEncryptionService encryptionService;

    setUp(() {
      encryptionService = VaultEncryptionService();
    });

    test('encrypts plaintext to AES-256 envelope and decrypts back correctly',
        () async {
      const originalPlaintext = '{"secret": "sensitive cardholder data 1234"}';

      final encryptedJson = await encryptionService.encrypt(originalPlaintext);

      // Verify envelope structure
      expect(encryptedJson, isNotEmpty);
      expect(encryptedJson.contains('cipher'), isTrue);
      expect(encryptedJson.contains('AES-256-CBC'), isTrue);
      expect(encryptedJson.contains('iv'), isTrue);
      expect(encryptedJson.contains('data'), isTrue);

      // Ensure ciphertext does not expose sensitive plaintext
      expect(encryptedJson.contains('sensitive cardholder data'), isFalse);

      // Decrypt and verify matching plaintext
      final decrypted = await encryptionService.decrypt(encryptedJson);
      expect(decrypted, equals(originalPlaintext));
    });

    test('produces different ciphertexts and IVs for identical plaintexts (IND-CPA)',
        () async {
      const text = 'SAME_CARD_NUMBER_1234567812345678';
      final enc1 = await encryptionService.encrypt(text);
      final enc2 = await encryptionService.encrypt(text);

      expect(enc1, isNot(equals(enc2)));

      final Map<String, dynamic> env1 = jsonDecode(enc1);
      final Map<String, dynamic> env2 = jsonDecode(enc2);
      expect(env1['iv'], isNot(equals(env2['iv'])));
      expect(env1['data'], isNot(equals(env2['data'])));
    });

    test('supports backward compatibility with legacy unencrypted plaintext',
        () async {
      const legacyJson = '{"version":1,"cards":[{"id":"card1"}]}';
      final result = await encryptionService.decrypt(legacyJson);
      expect(result, equals(legacyJson));
    });

    test('CardRepository loads and saves cards through encryption service',
        () async {
      final repo = CardRepository(encryptionService: encryptionService);
      const testCard = CardModel(
        id: 'test_encrypted_card',
        nickname: 'Encrypted Vault Card',
        cardholderName: 'VAULT HOLDER',
        bankName: 'CIPHER BANK',
        cardType: 'credit',
        cardNetwork: 'Visa',
        cardNumber: '4111 2222 3333 4444',
        expiryMonth: '10',
        expiryYear: '2028',
        colorHex: '#1E40AF',
      );

      await repo.saveCards([testCard]);
      final loaded = await repo.loadCards();

      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('test_encrypted_card'));
      expect(loaded.first.cardNumber, equals('4111 2222 3333 4444'));
    });
  });
}
