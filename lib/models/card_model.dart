import 'package:flutter/material.dart';

class CardModel {
  final String id;
  final String nickname;
  final String cardholderName;
  final String bankName;
  final String cardType;
  final String cardNetwork;
  final String cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvv;
  final String colorHex;

  const CardModel({
    required this.id,
    required this.nickname,
    required this.cardholderName,
    required this.bankName,
    required this.cardType,
    required this.cardNetwork,
    required this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
    required this.colorHex,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      cardholderName: json['cardholder_name'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      cardType: json['card_type'] as String? ?? '',
      cardNetwork: json['card_network'] as String? ?? '',
      cardNumber: json['card_number'] as String? ?? '',
      expiryMonth: json['expiry_month'] as String?,
      expiryYear: json['expiry_year'] as String?,
      cvv: json['cvv'] as String?,
      colorHex: json['color'] as String? ?? '#2455C3',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'cardholder_name': cardholderName,
      'bank_name': bankName,
      'card_type': cardType,
      'card_network': cardNetwork,
      'card_number': cardNumber,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cvv': cvv,
      'color': colorHex,
    };
  }

  /// Parses the hex color string (e.g. #2455C3) into a Flutter [Color].
  Color get cardColor {
    final hex = colorHex.replaceAll('#', '').trim();
    if (hex.length == 6) {
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) return Color(value);
    } else if (hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(value);
    }
    return const Color(0xFF2455C3);
  }

  /// Formatted expiration string, e.g. "12/28"
  String get formattedExpiry {
    if (expiryMonth == null || expiryYear == null) return '';
    final yr = expiryYear!.length >= 4
        ? expiryYear!.substring(expiryYear!.length - 2)
        : expiryYear!;
    return '$expiryMonth/$yr';
  }

  bool get isCredit => cardType.toLowerCase() == 'credit';
  bool get isDebit => cardType.toLowerCase() == 'debit';
  bool get isPrepaid => cardType.toLowerCase() == 'prepaid';
  bool get isGift => cardType.toLowerCase() == 'gift';
}
