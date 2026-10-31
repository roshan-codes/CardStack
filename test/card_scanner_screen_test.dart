import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/models/card_model.dart';
import 'package:card_stack/screens/card_scanner_screen.dart';

void main() {
  group('CardScannerScreen Tests', () {
    testWidgets('renders scanner UI and saves scanned card',
        (WidgetTester tester) async {
      CardModel? scannedCard;

      await tester.pumpWidget(
        MaterialApp(
          home: CardScannerScreen(
            onCardScanned: (card) {
              scannedCard = card;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Scanner UI elements
      expect(find.text('Scan Payment Card'), findsOneWidget);
      expect(find.text('Align card edges inside the frame'), findsOneWidget);
      expect(find.byKey(const Key('capture_card_button')), findsOneWidget);

      // Tap the capture card button
      await tester.tap(find.byKey(const Key('capture_card_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify confirmation sheet appears
      expect(find.text('Card Detected Offline'), findsOneWidget);
      expect(find.byKey(const Key('scanned_number_field')), findsOneWidget);
      expect(find.byKey(const Key('save_scanned_card_button')), findsOneWidget);

      // Save card to stack
      await tester.tap(find.byKey(const Key('save_scanned_card_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify onCardScanned was called with valid card
      expect(scannedCard, isNotNull);
      expect(scannedCard!.cardNumber, isNotEmpty);
      expect(scannedCard!.bankName, isNotEmpty);
    });
  });
}
