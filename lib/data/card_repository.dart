import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';

class CardRepository {
  static const String _assetPath = 'assets/data/cards.json';

  /// Hardcoded fallback / initial mock JSON in case assets are not available
  /// or when running pure Dart unit tests.
  static const String rawMockCardsJson = '''{
  "cards": [
    {
      "id": "card_001",
      "nickname": "HDFC Millennia",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "HDFC Bank",
      "card_type": "credit",
      "card_network": "Visa",
      "card_number": "XXXX XXXX XXXX 4567",
      "expiry_month": "12",
      "expiry_year": "2028",
      "cvv": null,
      "color": "#2455C3"
    },
    {
      "id": "card_002",
      "nickname": "ICICI Amazon Pay",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "ICICI Bank",
      "card_type": "credit",
      "card_network": "Mastercard",
      "card_number": "XXXX XXXX XXXX 8765",
      "expiry_month": "08",
      "expiry_year": "2029",
      "cvv": null,
      "color": "#D83B45"
    },
    {
      "id": "card_003",
      "nickname": "SBI SimplyCLICK",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "SBI Card",
      "card_type": "credit",
      "card_network": "Visa",
      "card_number": "XXXX XXXX XXXX 2341",
      "expiry_month": "04",
      "expiry_year": "2027",
      "cvv": null,
      "color": "#202A3C"
    },
    {
      "id": "card_004",
      "nickname": "Axis Flipkart",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "Axis Bank",
      "card_type": "credit",
      "card_network": "Mastercard",
      "card_number": "XXXX XXXX XXXX 9988",
      "expiry_month": "11",
      "expiry_year": "2030",
      "cvv": null,
      "color": "#7029C8"
    },
    {
      "id": "card_005",
      "nickname": "Kotak League",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "Kotak Mahindra Bank",
      "card_type": "credit",
      "card_network": "Visa",
      "card_number": "XXXX XXXX XXXX 1122",
      "expiry_month": "06",
      "expiry_year": "2028",
      "cvv": null,
      "color": "#D47B35"
    },
    {
      "id": "card_006",
      "nickname": "HDFC Salary Account",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "HDFC Bank",
      "card_type": "debit",
      "card_network": "RuPay",
      "card_number": "XXXX XXXX XXXX 7788",
      "expiry_month": "03",
      "expiry_year": "2029",
      "cvv": null,
      "color": "#147E9C"
    },
    {
      "id": "card_007",
      "nickname": "SBI Global Debit",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "State Bank of India",
      "card_type": "debit",
      "card_network": "Visa",
      "card_number": "XXXX XXXX XXXX 6655",
      "expiry_month": "09",
      "expiry_year": "2028",
      "cvv": null,
      "color": "#2455A4"
    },
    {
      "id": "card_008",
      "nickname": "Axis Burgundy Debit",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "Axis Bank",
      "card_type": "debit",
      "card_network": "Mastercard",
      "card_number": "XXXX XXXX XXXX 3344",
      "expiry_month": "05",
      "expiry_year": "2030",
      "cvv": null,
      "color": "#9B2448"
    },
    {
      "id": "card_009",
      "nickname": "Forex Travel Card",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "BookMyForex",
      "card_type": "prepaid",
      "card_network": "Visa",
      "card_number": "XXXX XXXX XXXX 5566",
      "expiry_month": "07",
      "expiry_year": "2029",
      "cvv": null,
      "color": "#168C78"
    },
    {
      "id": "card_010",
      "nickname": "Amazon Gift Card",
      "cardholder_name": "Rahul Sharma",
      "bank_name": "Amazon",
      "card_type": "gift",
      "card_network": "Other",
      "card_number": "DEMO-GIFT-0010",
      "expiry_month": null,
      "expiry_year": null,
      "cvv": null,
      "color": "#E78B27"
    }
  ]
}''';


  static const String _storageFileName = 'cards_store.json';
  static List<CardModel>? _inMemoryTestStore;

  /// Loads cards from persistent device storage, falling back to assets/mock data on first launch.
  Future<List<CardModel>> loadCards() async {
    // 1. If in-memory test store is populated, use it
    if (_inMemoryTestStore != null) {
      return List<CardModel>.from(_inMemoryTestStore!);
    }

    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final loaded = parseCards(content);
          if (loaded.isNotEmpty) {
            return loaded;
          }
        }
      }
    } catch (_) {
      // Platform channel error (e.g. during test runner) or read error
    }

    // 2. Fall back to asset file or raw mock cards on first run
    List<CardModel> initialCards;
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      initialCards = parseCards(jsonString);
    } catch (_) {
      initialCards = parseCards(rawMockCardsJson);
    }

    // Persist initial cards so future launches use the persistent copy
    await saveCards(initialCards);
    return initialCards;
  }

  /// Saves the complete list of cards atomically to disk to prevent data corruption.
  Future<void> saveCards(List<CardModel> cards) async {
    _inMemoryTestStore = List<CardModel>.from(cards);

    try {
      final file = await _getStorageFile();
      if (file != null) {
        final data = {
          'version': 1,
          'updated_at': DateTime.now().toIso8601String(),
          'cards': cards.map((c) => c.toJson()).toList(),
        };
        final tempFile = File('${file.path}.tmp');
        await tempFile.writeAsString(jsonEncode(data), flush: true);
        await tempFile.rename(file.path);
      }
    } catch (_) {
      // Handle test environment or storage error gracefully
    }
  }

  /// Adds a new card to storage.
  Future<void> addCard(CardModel card) async {
    final current = await loadCards();
    current.insert(0, card);
    await saveCards(current);
  }

  /// Updates an existing card in storage.
  Future<void> updateCard(CardModel card) async {
    final current = await loadCards();
    final idx = current.indexWhere((c) => c.id == card.id);
    if (idx != -1) {
      current[idx] = card;
      await saveCards(current);
    }
  }

  /// Deletes a card from storage by its ID.
  Future<void> deleteCard(String id) async {
    final current = await loadCards();
    current.removeWhere((c) => c.id == id);
    await saveCards(current);
  }

  /// Helper to locate the application documents storage file safely.
  Future<File?> _getStorageFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_storageFileName');
    } catch (_) {
      return null;
    }
  }

  /// Synchronous helper to get parsed cards directly from memory
  static List<CardModel> getMockCards() {
    if (_inMemoryTestStore != null) {
      return List<CardModel>.from(_inMemoryTestStore!);
    }
    return parseCards(rawMockCardsJson);
  }

  /// Parses a JSON string containing the 'cards' list
  static List<CardModel> parseCards(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> cardsJson = data['cards'] as List<dynamic>? ?? [];
      return cardsJson
          .map((card) => CardModel.fromJson(card as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
