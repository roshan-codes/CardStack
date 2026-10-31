import 'card_network_detector.dart';

class ScannedCardData {
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cardholderName;
  final String? bankName;
  final String? cardNetwork;

  const ScannedCardData({
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cardholderName,
    this.bankName,
    this.cardNetwork,
  });

  bool get hasSufficientData =>
      cardNumber != null && cardNumber!.replaceAll(RegExp(r'\D'), '').length >= 12;

  String get formattedExpiry {
    if (expiryMonth == null || expiryYear == null) return '';
    return '$expiryMonth/$expiryYear';
  }
}

class CardOcrParser {
  /// Extracts credit/debit card details from raw OCR text lines offline.
  static ScannedCardData parse(List<String> rawLines) {
    String? foundCardNumber;
    String? foundExpiryMonth;
    String? foundExpiryYear;
    String? foundCardholderName;
    String? foundBankName;
    String? foundNetwork;

    // Known banks dictionary for offline keyword matching
    final knownBanks = [
      'HDFC Bank',
      'ICICI Bank',
      'State Bank of India',
      'SBI Card',
      'SBI',
      'Axis Bank',
      'Kotak Mahindra Bank',
      'Kotak Bank',
      'Kotak',
      'Citibank',
      'Bank of Baroda',
      'Punjab National Bank',
      'Amazon Pay',
      'BookMyForex',
      'Chase',
      'Bank of America',
      'Capital One',
      'Wells Fargo',
    ];

    final cleanedLines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in cleanedLines) {
      final upper = line.toUpperCase();

      // 1. Detect Bank
      if (foundBankName == null) {
        for (final bank in knownBanks) {
          if (upper.contains(bank.toUpperCase())) {
            foundBankName = bank;
            break;
          }
        }
      }

      // 2. Detect Card Network
      if (foundNetwork == null) {
        if (upper.contains('VISA')) {
          foundNetwork = 'Visa';
        } else if (upper.contains('MASTERCARD') || upper.contains('MASTER CARD')) {
          foundNetwork = 'Mastercard';
        } else if (upper.contains('RUPAY')) {
          foundNetwork = 'RuPay';
        } else if (upper.contains('AMERICAN EXPRESS') || upper.contains('AMEX')) {
          foundNetwork = 'American Express';
        } else if (upper.contains('DISCOVER')) {
          foundNetwork = 'Discover';
        }
      }

      // 3. Detect Card Number (13 to 19 digits, possibly space/dash separated)
      if (foundCardNumber == null) {
        // Look for 4 groups of 4 digits or continuous 15-16 digits
        final numMatch = RegExp(r'(?:\d[ -]*?){13,19}').firstMatch(line);
        if (numMatch != null) {
          final digitsOnly = numMatch.group(0)!.replaceAll(RegExp(r'\D'), '');
          if (digitsOnly.length >= 13 && digitsOnly.length <= 19) {
            // Format nicely in 4-digit blocks
            final buffer = StringBuffer();
            for (int i = 0; i < digitsOnly.length; i++) {
              if (i > 0 && i % 4 == 0) buffer.write(' ');
              buffer.write(digitsOnly[i]);
            }
            foundCardNumber = buffer.toString();

            // Infer network from IIN prefix rules if not already found
            if (foundNetwork == null) {
              final detected = CardNetworkDetector.detect(digitsOnly);
              if (!detected.isUnknown) {
                foundNetwork = detected.name;
              }
            }
          }
        }
      }

      // 4. Detect Expiry Date (MM/YY or MM/YYYY or VALID THRU MM/YY)
      if (foundExpiryMonth == null || foundExpiryYear == null) {
        final expMatch = RegExp(r'\b(0[1-9]|1[0-2])\s*[\/\-]\s*([0-9]{2}|[0-9]{4})\b')
            .firstMatch(line);
        if (expMatch != null) {
          foundExpiryMonth = expMatch.group(1);
          var yr = expMatch.group(2)!;
          if (yr.length == 4) {
            yr = yr.substring(2);
          }
          foundExpiryYear = yr;
        }
      }

      // 5. Detect Cardholder Name (Uppercase words, usually appearing after valid thru or bottom)
      if (foundCardholderName == null &&
          upper != 'VALID THRU' &&
          !upper.contains('CARD') &&
          !upper.contains('BANK') &&
          !upper.contains('VISA') &&
          !upper.contains('EXPIRES') &&
          !upper.contains('DEBIT') &&
          !upper.contains('CREDIT') &&
          RegExp(r'^[A-Z]{2,15}\s+[A-Z]{2,15}(\s+[A-Z]{2,15})?$').hasMatch(upper)) {
        foundCardholderName = line;
      }
    }

    return ScannedCardData(
      cardNumber: foundCardNumber,
      expiryMonth: foundExpiryMonth,
      expiryYear: foundExpiryYear,
      cardholderName: foundCardholderName,
      bankName: foundBankName,
      cardNetwork: foundNetwork,
    );
  }
}
