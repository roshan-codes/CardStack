import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/services/card_ocr_parser.dart';

void main() {
  group('CardOcrParser Tests', () {
    test('extracts Visa card details from OCR lines offline', () {
      final sampleLines = [
        'HDFC Bank',
        'PLATINUM',
        '4532 8899 1122 3344',
        'VALID THRU 12/28',
        'RAHUL SHARMA',
        'VISA',
      ];

      final result = CardOcrParser.parse(sampleLines);
      expect(result.hasSufficientData, true);
      expect(result.cardNumber, '4532 8899 1122 3344');
      expect(result.bankName, 'HDFC Bank');
      expect(result.expiryMonth, '12');
      expect(result.expiryYear, '28');
      expect(result.formattedExpiry, '12/28');
      expect(result.cardholderName, 'RAHUL SHARMA');
      expect(result.cardNetwork, 'Visa');
    });

    test('extracts Mastercard and detects network from card prefix', () {
      final sampleLines = [
        'Axis Bank',
        '5241 9988 7766 5544',
        'EXPIRES 08/29',
        'PRIYA PATEL',
      ];

      final result = CardOcrParser.parse(sampleLines);
      expect(result.cardNumber, '5241 9988 7766 5544');
      expect(result.cardNetwork, 'Mastercard');
      expect(result.bankName, 'Axis Bank');
      expect(result.expiryMonth, '08');
      expect(result.expiryYear, '29');
    });

    test('prioritizes VALID THRU over VALID FROM when both dates are present', () {
      final sampleLines = [
        'ICICI Bank',
        '4532 1111 2222 3333',
        'VALID FROM 03/22',
        'VALID THRU 03/27',
        'ANANYA VERMA',
      ];

      final result = CardOcrParser.parse(sampleLines);
      expect(result.expiryMonth, '03');
      expect(result.expiryYear, '27');
      expect(result.formattedExpiry, '03/27');
    });

    test('extracts expiry date when VALID THRU is split across lines', () {
      final sampleLines = [
        'State Bank of India',
        '6071 2233 4455 6677',
        'VALID THRU',
        '10/28',
        'AMIT KUMAR',
      ];

      final result = CardOcrParser.parse(sampleLines);
      expect(result.expiryMonth, '10');
      expect(result.expiryYear, '28');
    });

    test('handles OCR letter O substitution and space separation', () {
      final sampleLines = [
        'Kotak Bank',
        '4111 2222 3333 4444',
        'GOOD THRU O5/30',
        'VIKRAM SINGH',
      ];

      final result = CardOcrParser.parse(sampleLines);
      expect(result.expiryMonth, '05');
      expect(result.expiryYear, '30');
    });
  });
}
