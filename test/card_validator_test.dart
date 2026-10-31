import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/services/card_validator.dart';

void main() {
  group('CardValidator Tests', () {
    test('validateLuhn correctly verifies valid and invalid card numbers', () {
      // Valid Luhn test numbers (15 & 16 digits)
      expect(CardValidator.validateLuhn('4242 4242 4242 4242'), isTrue); // Stripe/Visa valid Luhn
      expect(CardValidator.validateLuhn('4000 0000 0000 0002'), isTrue);
      expect(CardValidator.validateLuhn('4532 0150 1234 5671'), isTrue);

      // Invalid Luhn numbers
      expect(CardValidator.validateLuhn('4242 4242 4242 4243'), isFalse);
      expect(CardValidator.validateLuhn('4532 0150 1234 5675'), isFalse);
      expect(CardValidator.validateLuhn('0000 0000 0000 0001'), isFalse);
    });

    test('validateCardNumber checks length and format', () {
      expect(CardValidator.validateCardNumber(''), 'Enter a card number');
      expect(CardValidator.validateCardNumber('12345'), 'Card number must be 13-19 digits');
      expect(CardValidator.validateCardNumber('XXXX XXXX XXXX 4567'), isNull);
      expect(CardValidator.validateCardNumber('4242 4242 4242 4242'), isNull);
    });

    test('validateExpiry checks valid, invalid, and expired dates', () {
      expect(CardValidator.validateExpiry(''), 'Enter MM/YY');
      expect(CardValidator.validateExpiry('13/28'), 'Invalid month (01-12)');
      expect(CardValidator.validateExpiry('00/28'), 'Invalid month (01-12)');
      expect(CardValidator.validateExpiry('12/19'), 'Card has already expired');
      expect(CardValidator.validateExpiry('12/29'), isNull);
    });

    test('validateCvv checks lengths and allows optional empty value', () {
      expect(CardValidator.validateCvv(''), isNull);
      expect(CardValidator.validateCvv('abc'), 'CVV must contain numbers only');
      expect(CardValidator.validateCvv('12'), 'CVV must be 3 or 4 digits');
      expect(CardValidator.validateCvv('123'), isNull);
      expect(CardValidator.validateCvv('1234'), isNull);
      expect(CardValidator.validateCvv('123', cardNetwork: 'American Express'), 'Amex CVV must be 4 digits');
      expect(CardValidator.validateCvv('1234', cardNetwork: 'American Express'), isNull);
    });
  });
}
