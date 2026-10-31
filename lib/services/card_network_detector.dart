import 'dart:convert';

/// Represents a detected card network result
class CardNetworkInfo {
  final String name;
  final String code;
  final String? logo;
  final bool allowManualSelection;

  const CardNetworkInfo({
    required this.name,
    required this.code,
    this.logo,
    this.allowManualSelection = false,
  });

  bool get isUnknown => code == 'unknown';
  bool get isVisa => code == 'visa';
  bool get isMastercard => code == 'mastercard';
  bool get isRupay => code == 'rupay';
  bool get isAmex => code == 'amex';
  bool get isDiscover => code == 'discover';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardNetworkInfo &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CardNetworkInfo(name: $name, code: $code)';
}

/// A single IIN prefix rule
class PrefixRule {
  final String start;
  final String? end;
  final int length;

  const PrefixRule({
    required this.start,
    this.end,
    required this.length,
  });

  factory PrefixRule.fromJson(Map<String, dynamic> json) {
    return PrefixRule(
      start: json['start'].toString(),
      end: json['end']?.toString(),
      length: json['length'] as int? ?? (json['start'] as String).length,
    );
  }

  /// Evaluates whether the card number digits match this prefix rule.
  bool matches(String digits) {
    if (digits.length < length) return false;
    final prefix = digits.substring(0, length);

    if (end != null) {
      final val = int.tryParse(prefix);
      final startVal = int.tryParse(start);
      final endVal = int.tryParse(end!);
      if (val == null || startVal == null || endVal == null) return false;
      return val >= startVal && val <= endVal;
    } else {
      return prefix == start;
    }
  }
}

/// A configured card network with its associated prefix rules
class ConfiguredNetwork {
  final String name;
  final String code;
  final String logo;
  final List<PrefixRule> prefixRules;

  const ConfiguredNetwork({
    required this.name,
    required this.code,
    required this.logo,
    required this.prefixRules,
  });

  factory ConfiguredNetwork.fromJson(Map<String, dynamic> json) {
    final rules = (json['prefix_rules'] as List? ?? [])
        .map((r) => PrefixRule.fromJson(r as Map<String, dynamic>))
        .toList();

    return ConfiguredNetwork(
      name: json['name'] as String,
      code: json['code'] as String,
      logo: json['logo'] as String,
      prefixRules: rules,
    );
  }

  CardNetworkInfo toInfo({bool allowManualSelection = false}) {
    return CardNetworkInfo(
      name: name,
      code: code,
      logo: logo,
      allowManualSelection: allowManualSelection,
    );
  }
}

/// Detection engine implementing IIN prefix matching according to the configuration specification.
class CardNetworkDetector {
  static const String defaultConfigJson = '''{
  "card_network_detection": {
    "enabled": true,
    "method": "iin_prefix_matching",
    "detect_from": "card_number",
    "networks": [
      {
        "name": "Visa",
        "code": "visa",
        "prefix_rules": [
          {
            "start": "4",
            "length": 1
          }
        ],
        "logo": "assets/cards/visa.png"
      },
      {
        "name": "Mastercard",
        "code": "mastercard",
        "prefix_rules": [
          {
            "start": "51",
            "end": "55",
            "length": 2
          },
          {
            "start": "2221",
            "end": "2720",
            "length": 4
          }
        ],
        "logo": "assets/cards/mastercard.png"
      },
      {
        "name": "RuPay",
        "code": "rupay",
        "prefix_rules": [
          {
            "start": "60",
            "length": 2
          },
          {
            "start": "65",
            "length": 2
          },
          {
            "start": "81",
            "length": 2
          },
          {
            "start": "82",
            "length": 2
          },
          {
            "start": "508",
            "length": 3
          }
        ],
        "logo": "assets/cards/rupay.png"
      },
      {
        "name": "American Express",
        "code": "amex",
        "prefix_rules": [
          {
            "start": "34",
            "length": 2
          },
          {
            "start": "37",
            "length": 2
          }
        ],
        "logo": "assets/cards/amex.png"
      },
      {
        "name": "Discover",
        "code": "discover",
        "prefix_rules": [
          {
            "start": "6011",
            "length": 4
          },
          {
            "start": "65",
            "length": 2
          }
        ],
        "logo": "assets/cards/discover.png"
      }
    ],
    "fallback": {
      "name": "Unknown",
      "code": "unknown",
      "allow_manual_selection": true
    }
  }
}''';

  static CardNetworkDetector? _instance;
  static CardNetworkDetector get instance =>
      _instance ??= CardNetworkDetector.fromJsonString(defaultConfigJson);

  final bool enabled;
  final String method;
  final String detectFrom;
  final List<ConfiguredNetwork> networks;
  final CardNetworkInfo fallback;

  CardNetworkDetector({
    required this.enabled,
    required this.method,
    required this.detectFrom,
    required this.networks,
    required this.fallback,
  });

  factory CardNetworkDetector.fromJsonString(String jsonString) {
    final Map<String, dynamic> root = jsonDecode(jsonString);
    final config = root['card_network_detection'] as Map<String, dynamic>;

    final networksList = (config['networks'] as List? ?? [])
        .map((net) => ConfiguredNetwork.fromJson(net as Map<String, dynamic>))
        .toList();

    final fallbackMap = config['fallback'] as Map<String, dynamic>? ?? {};
    final fallbackInfo = CardNetworkInfo(
      name: fallbackMap['name'] as String? ?? 'Unknown',
      code: fallbackMap['code'] as String? ?? 'unknown',
      allowManualSelection:
          fallbackMap['allow_manual_selection'] as bool? ?? true,
    );

    return CardNetworkDetector(
      enabled: config['enabled'] as bool? ?? true,
      method: config['method'] as String? ?? 'iin_prefix_matching',
      detectFrom: config['detect_from'] as String? ?? 'card_number',
      networks: networksList,
      fallback: fallbackInfo,
    );
  }

  /// Returns all configured supported networks including fallback
  List<CardNetworkInfo> get supportedNetworks {
    return [
      ...networks.map((n) => n.toInfo()),
      fallback,
    ];
  }

  /// Detects card network from a raw or formatted card number.
  /// Prioritizes longer prefix matches (e.g. 4-digit prefixes like Discover 6011
  /// over 2-digit prefixes like RuPay 60).
  CardNetworkInfo detectNetwork(String? cardNumber) {
    if (!enabled || cardNumber == null) return fallback;

    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return fallback;

    // Collect all matching candidate rules across all networks
    ConfiguredNetwork? bestMatchNetwork;
    int maxMatchedLength = -1;

    for (final network in networks) {
      for (final rule in network.prefixRules) {
        if (rule.matches(digits)) {
          // If this rule matches with a longer prefix length, it has higher specificity
          if (rule.length > maxMatchedLength) {
            maxMatchedLength = rule.length;
            bestMatchNetwork = network;
          }
        }
      }
    }

    if (bestMatchNetwork != null) {
      return bestMatchNetwork.toInfo();
    }

    return fallback;
  }

  /// Convenience static detector
  static CardNetworkInfo detect(String? cardNumber) {
    return instance.detectNetwork(cardNumber);
  }

  /// Finds a network by its standard name or code
  static CardNetworkInfo fromIdentifier(String identifier) {
    final clean = identifier.trim().toLowerCase();
    for (final n in instance.networks) {
      if (n.code.toLowerCase() == clean || n.name.toLowerCase() == clean) {
        return n.toInfo();
      }
    }
    if (clean.contains('visa')) return instance.networks.firstWhere((n) => n.code == 'visa').toInfo();
    if (clean.contains('master')) return instance.networks.firstWhere((n) => n.code == 'mastercard').toInfo();
    if (clean.contains('rupay')) return instance.networks.firstWhere((n) => n.code == 'rupay').toInfo();
    if (clean.contains('amex') || clean.contains('american')) {
      return instance.networks.firstWhere((n) => n.code == 'amex').toInfo();
    }
    if (clean.contains('discover')) {
      return instance.networks.firstWhere((n) => n.code == 'discover').toInfo();
    }
    return instance.fallback;
  }
}
