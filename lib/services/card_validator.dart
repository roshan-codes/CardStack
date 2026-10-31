/// Financial validation rules for credit and debit cards
class CardValidator {
  /// Validates a card number using the ISO/IEC 7812 Luhn (Mod 10) algorithm.
  static bool validateLuhn(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n -= 9;
        }
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Form field validator for card numbers.
  static String? validateCardNumber(String? value, {bool strictLuhn = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a card number';
    }
    // Allow masked numbers from saved cards (e.g. XXXX XXXX XXXX 4567)
    if (value.toUpperCase().contains('X') || value.contains('*')) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) {
      return 'Card number must be 13-19 digits';
    }
    if (strictLuhn && !validateLuhn(digits)) {
      return 'Invalid card number (checksum failed)';
    }
    return null;
  }

  /// Form field validator for expiration date (MM/YY or MMYY).
  static String? validateExpiry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter MM/YY';
    }
    final cleaned = value.trim();
    List<String> parts;
    if (cleaned.contains('/')) {
      parts = cleaned.split('/');
    } else if (cleaned.length == 4) {
      parts = [cleaned.substring(0, 2), cleaned.substring(2)];
    } else {
      return 'Enter valid MM/YY';
    }

    if (parts.length != 2 || parts[0].length != 2 || parts[1].length != 2) {
      return 'Enter valid MM/YY';
    }

    final month = int.tryParse(parts[0]);
    final yearSuffix = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return 'Invalid month (01-12)';
    }

    if (yearSuffix == null) {
      return 'Invalid year';
    }

    final fullYear = 2000 + yearSuffix;
    final now = DateTime.now();
    // Card expires at the end of the specified month
    final cardExpiry = DateTime(fullYear, month + 1, 0, 23, 59, 59);

    if (cardExpiry.isBefore(now)) {
      return 'Card has already expired';
    }

    // Sanity check: Expiry should not be more than 25 years into future
    if (fullYear > now.year + 25) {
      return 'Expiry year is too far in future';
    }

    return null;
  }

  /// Form field validator for CVV.
  static String? validateCvv(String? value, {String cardNetwork = ''}) {
    if (value == null || value.trim().isEmpty) {
      return null; // CVV is optional to store
    }
    final cleaned = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'CVV must contain numbers only';
    }
    final isAmex = cardNetwork.toLowerCase().contains('american') ||
        cardNetwork.toLowerCase().contains('amex');

    if (isAmex) {
      if (cleaned.length != 4) {
        return 'Amex CVV must be 4 digits';
      }
    } else {
      if (cleaned.length != 3 && cleaned.length != 4) {
        return 'CVV must be 3 or 4 digits';
      }
    }
    return null;
  }
}
