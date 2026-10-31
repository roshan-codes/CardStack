import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/models/card_model.dart';

void main() {
  group('CardRepository & CardModel Tests', () {
    const sampleCard = CardModel(
      id: 'card_custom_01',
      nickname: 'Sapphire Preferred',
      bankName: 'Chase',
      cardholderName: 'Alex Morgan',
      cardType: 'credit',
      cardNetwork: 'Visa',
      cardNumber: '4111 2222 3333 4444',
      expiryMonth: '12',
      expiryYear: '2028',
      cvv: '123',
      colorHex: '#2455C3',
    );

    test('parses and formats CardModel fields correctly', () {
      expect(sampleCard.id, 'card_custom_01');
      expect(sampleCard.nickname, 'Sapphire Preferred');
      expect(sampleCard.bankName, 'Chase');
      expect(sampleCard.cardholderName, 'Alex Morgan');
      expect(sampleCard.cardType, 'credit');
      expect(sampleCard.cardNetwork, 'Visa');
      expect(sampleCard.cardNumber, '4111 2222 3333 4444');
      expect(sampleCard.expiryMonth, '12');
      expect(sampleCard.expiryYear, '2028');
      expect(sampleCard.formattedExpiry, '12/28');
      expect(sampleCard.isCredit, true);
      expect(sampleCard.colorHex, '#2455C3');
      expect(sampleCard.cardColor.value, 0xFF2455C3);
    });

    test('serializes and deserializes to JSON properly', () {
      final json = sampleCard.toJson();
      expect(json['id'], 'card_custom_01');
      expect(json['color'], '#2455C3');

      final reconstructed = CardModel.fromJson(json);
      expect(reconstructed.id, sampleCard.id);
      expect(reconstructed.nickname, sampleCard.nickname);
      expect(reconstructed.cardNumber, sampleCard.cardNumber);
      expect(reconstructed.bankName, sampleCard.bankName);
    });
  });
}
