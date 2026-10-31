import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';
import '../services/vault_encryption_service.dart';

class CardRepository {
  static const String _assetPath = 'assets/data/cards.json';

  static const String rawMockCardsJson = '''{
  "cards": [
    {
      "id": "card_hdfc_millennia",
      "nickname": "HDFC Millennia",
      "cardholder_name": "RAHUL SHARMA",
      "bank_name": "HDFC BANK",
      "card_type": "credit",
      "card_network": "Visa",
      "card_number": "XXXX XXXX XXXX 4567",
      "expiry_month": "12",
      "expiry_year": "2028",
      "cvv": null,
      "color": "#1E40AF"
    },
    {
      "id": "card_icici_amazon",
      "nickname": "ICICI Amazon Pay",
      "cardholder_name": "RAHUL SHARMA",
      "bank_name": "ICICI BANK",
      "card_type": "credit",
      "card_network": "Mastercard",
      "card_number": "XXXX XXXX XXXX 8765",
      "expiry_month": "08",
      "expiry_year": "2029",
      "cvv": null,
      "color": "#DC2626"
    },
    {
      "id": "card_sbi_simplysave",
      "nickname": "SBI SimplySAVE",
      "cardholder_name": "RAHUL SHARMA",
      "bank_name": "SBI BANK",
      "card_type": "debit",
      "card_network": "RuPay",
      "card_number": "XXXX XXXX XXXX 1122",
      "expiry_month": "11",
      "expiry_year": "2027",
      "cvv": null,
      "color": "#0F172A"
    }
  ]
}''';

  static const String _storageFileName = 'cards_store.json';
  static List<CardModel>? _inMemoryTestStore;
  final VaultEncryptionService _encryptionService;

  CardRepository({VaultEncryptionService? encryptionService})
      : _encryptionService = encryptionService ?? VaultEncryptionService();

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
          final decrypted = await _encryptionService.decrypt(content);
          final loaded = parseCards(decrypted);
          if (loaded.isNotEmpty) {
            // Automatically upgrade legacy plaintext file to AES-256 encrypted storage
            if (!content.contains(VaultEncryptionService.cipherIdentifier)) {
              await saveCards(loaded);
            }
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

  /// Completely wipes all stored cards from storage and test store.
  Future<void> clearAllCards() async {
    _inMemoryTestStore = [];
    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
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
        final plainJson = jsonEncode(data);
        final encryptedPayload = await _encryptionService.encrypt(plainJson);

        final tempFile = File('${file.path}.tmp');
        await tempFile.writeAsString(encryptedPayload, flush: true);
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
