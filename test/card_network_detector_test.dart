import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/services/card_network_detector.dart';

void main() {
  group('CardNetworkDetector IIN Prefix Matching Tests', () {
    final detector = CardNetworkDetector.instance;

    test('Initializes correctly from configuration', () {
      expect(detector.enabled, isTrue);
      expect(detector.method, 'iin_prefix_matching');
      expect(detector.detectFrom, 'card_number');
      expect(detector.networks.length, 5);
      expect(detector.fallback.name, 'Unknown');
      expect(detector.fallback.code, 'unknown');
      expect(detector.fallback.allowManualSelection, isTrue);
    });

    test('Detects Visa with prefix "4"', () {
      final res1 = detector.detectNetwork('4');
      expect(res1.name, 'Visa');
      expect(res1.code, 'visa');
      expect(res1.logo, 'assets/cards/visa.png');

      final res2 = detector.detectNetwork('4532 1122 3344 5566');
      expect(res2.name, 'Visa');
      expect(res2.code, 'visa');
    });

    test('Detects Mastercard with 51-55 and 2221-2720 prefixes', () {
      // 51 - 55 range
      expect(detector.detectNetwork('5100 0000 0000 0000').name, 'Mastercard');
      expect(detector.detectNetwork('5345 6789 0123 4567').name, 'Mastercard');
      expect(detector.detectNetwork('5599 9999 9999 9999').name, 'Mastercard');

      // 2221 - 2720 range
      expect(detector.detectNetwork('2221 0000 0000 0000').name, 'Mastercard');
      expect(detector.detectNetwork('2500 1234 5678 9012').name, 'Mastercard');
      expect(detector.detectNetwork('2720 9999 9999 9999').name, 'Mastercard');
    });

    test('Detects RuPay with 60, 65, 81, 82, and 508 prefixes', () {
      // 60 (excluding 6011 which is Discover)
      expect(detector.detectNetwork('6080 1234 5678 9012').name, 'RuPay');
      // 65
      expect(detector.detectNetwork('6521 1234 5678 9012').name, 'RuPay');
      // 81
      expect(detector.detectNetwork('8100 0000 0000 0000').name, 'RuPay');
      // 82
      expect(detector.detectNetwork('8200 0000 0000 0000').name, 'RuPay');
      // 508
      expect(detector.detectNetwork('5081 2345 6789 0123').name, 'RuPay');
    });

    test('Detects American Express with 34 and 37 prefixes', () {
      expect(detector.detectNetwork('3400 0000 0000 000').name, 'American Express');
      expect(detector.detectNetwork('3782 8224 6310 005').name, 'American Express');
      expect(detector.detectNetwork('3782 8224 6310 005').code, 'amex');
      expect(detector.detectNetwork('3782 8224 6310 005').logo, 'assets/cards/amex.png');
    });

    test('Detects Discover with 6011 and 65 prefixes (longer prefix priority over 60)', () {
      // 6011 is 4-digit prefix matching Discover
      final res = detector.detectNetwork('6011 0000 0000 0000');
      expect(res.name, 'Discover');
      expect(res.code, 'discover');
      expect(res.logo, 'assets/cards/discover.png');
    });

    test('Returns Unknown fallback for unassigned card prefixes', () {
      final res1 = detector.detectNetwork('9999 0000 0000 0000');
      expect(res1.name, 'Unknown');
      expect(res1.code, 'unknown');
      expect(res1.allowManualSelection, isTrue);

      final res2 = detector.detectNetwork('');
      expect(res2.isUnknown, isTrue);

      final res3 = detector.detectNetwork(null);
      expect(res3.isUnknown, isTrue);
    });

    test('fromIdentifier maps correctly', () {
      expect(CardNetworkDetector.fromIdentifier('visa').name, 'Visa');
      expect(CardNetworkDetector.fromIdentifier('mastercard').name, 'Mastercard');
      expect(CardNetworkDetector.fromIdentifier('rupay').name, 'RuPay');
      expect(CardNetworkDetector.fromIdentifier('amex').name, 'American Express');
      expect(CardNetworkDetector.fromIdentifier('discover').name, 'Discover');
      expect(CardNetworkDetector.fromIdentifier('other').name, 'Unknown');
    });
  });
}
