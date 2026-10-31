import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/models/card_model.dart';
import 'package:card_stack/data/card_repository.dart';

void main() {
  group('CardRepository & CardModel Tests', () {
    test('parses all 10 mock cards correctly', () {
      final cards = CardRepository.getMockCards();
      expect(cards.length, 10);

      final first = cards.first;
      expect(first.id, 'card_001');
      expect(first.nickname, 'HDFC Millennia');
      expect(first.bankName, 'HDFC Bank');
      expect(first.cardholderName, 'Rahul Sharma');
      expect(first.cardType, 'credit');
      expect(first.cardNetwork, 'Visa');
      expect(first.cardNumber, 'XXXX XXXX XXXX 4567');
      expect(first.expiryMonth, '12');
      expect(first.expiryYear, '2028');
      expect(first.formattedExpiry, '12/28');
      expect(first.isCredit, true);
      expect(first.colorHex, '#2455C3');
      expect(first.cardColor.value, 0xFF2455C3);

      final giftCard = cards.last;
      expect(giftCard.id, 'card_010');
      expect(giftCard.nickname, 'Amazon Gift Card');
      expect(giftCard.isGift, true);
      expect(giftCard.formattedExpiry, '');
    });

    test('serializes to JSON properly', () {
      final cards = CardRepository.getMockCards();
      final json = cards.first.toJson();
      expect(json['id'], 'card_001');
      expect(json['color'], '#2455C3');

      final reconstructed = CardModel.fromJson(json);
      expect(reconstructed.id, cards.first.id);
      expect(reconstructed.nickname, cards.first.nickname);
    });
  });
}
