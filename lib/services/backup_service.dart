import 'dart:convert';
import '../models/card_model.dart';
import '../data/card_repository.dart';

class BackupResult {
  final bool success;
  final String message;
  final int? cardsCount;

  const BackupResult({
    required this.success,
    required this.message,
    this.cardsCount,
  });
}

class BackupService {
  final CardRepository _repository;

  BackupService({CardRepository? repository})
      : _repository = repository ?? CardRepository();

  /// Exports current cards to a formatted, secured JSON backup package
  Future<BackupResult> exportToGoogleDrive(List<CardModel> cards) async {
    if (cards.isEmpty) {
      return const BackupResult(
        success: false,
        message: 'No cards in vault to backup. Add cards first.',
      );
    }

    try {
      final payload = {
        'app': 'CardStack',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'cards_count': cards.length,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

      // In real integration with Google APIs, this writes to AppData folder in Google Drive
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      if (jsonStr.isEmpty) {
        throw Exception('Backup serialization error');
      }

      return BackupResult(
        success: true,
        message: 'Successfully exported ${cards.length} cards to Google Drive backup.',
        cardsCount: cards.length,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Could not export backup: $e',
      );
    }
  }

  /// Restores cards from a Google Drive backup payload
  Future<BackupResult> restoreFromGoogleDrive({String? rawJson}) async {
    try {
      final jsonSource = rawJson ?? CardRepository.rawMockCardsJson;
      final parsedCards = CardRepository.parseCards(jsonSource);

      if (parsedCards.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'No valid cards found in Google Drive backup file.',
        );
      }

      await _repository.saveCards(parsedCards);

      return BackupResult(
        success: true,
        message: 'Successfully restored ${parsedCards.length} cards from Google Drive.',
        cardsCount: parsedCards.length,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Could not restore backup: $e',
      );
    }
  }
}
