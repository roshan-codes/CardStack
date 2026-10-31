import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/data/card_repository.dart';
import 'package:card_stack/models/card_model.dart';

void main() {
  group('CardRepository Persistence and CRUD Tests', () {
    late CardRepository repository;

    setUp(() {
      repository = CardRepository();
    });

    test('loadCards loads default mock cards on initial launch', () async {
      final cards = await repository.loadCards();
      expect(cards, isNotEmpty);
      expect(cards.any((c) => c.nickname.contains('Millennia')), isTrue);
    });

    test('addCard prepends new card and persists it', () async {
      const newCard = CardModel(
        id: 'test_persist_1',
        nickname: 'Test Sapphire',
        cardholderName: 'Alice Smith',
        bankName: 'Chase',
        cardType: 'credit',
        cardNetwork: 'Visa',
        cardNumber: '4111 2222 3333 4444',
        expiryMonth: '10',
        expiryYear: '2029',
        cvv: '123',
        colorHex: '#2563EB',
      );

      await repository.addCard(newCard);
      final cards = await repository.loadCards();
      expect(cards.first.id, 'test_persist_1');
      expect(cards.first.nickname, 'Test Sapphire');
    });

    test('updateCard modifies existing card and persists changes', () async {
      const updatedCard = CardModel(
        id: 'test_persist_1',
        nickname: 'Test Sapphire Preferred',
        cardholderName: 'Alice Smith',
        bankName: 'Chase',
        cardType: 'credit',
        cardNetwork: 'Visa',
        cardNumber: '4111 2222 3333 4444',
        expiryMonth: '10',
        expiryYear: '2030',
        cvv: '123',
        colorHex: '#1D4ED8',
      );

      await repository.updateCard(updatedCard);
      final cards = await repository.loadCards();
      final found = cards.firstWhere((c) => c.id == 'test_persist_1');
      expect(found.nickname, 'Test Sapphire Preferred');
      expect(found.expiryYear, '2030');
    });

    test('deleteCard removes card and persists changes', () async {
      await repository.deleteCard('test_persist_1');
      final cards = await repository.loadCards();
      expect(cards.any((c) => c.id == 'test_persist_1'), isFalse);
    });
  });
}
