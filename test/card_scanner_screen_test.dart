import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/models/card_model.dart';
import 'package:card_stack/screens/card_scanner_screen.dart';

void main() {
  group('CardScannerScreen Tests', () {
    testWidgets(
        'shows snackbar when card number is not readable and does not add dummy details',
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

      // Tap capture card button when camera/OCR has no readable card
      await tester.tap(find.byKey(const Key('capture_card_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify SnackBar appears indicating card number not readable
      expect(
        find.textContaining('Card number not readable'),
        findsOneWidget,
      );

      // Verify confirmation sheet did NOT open and no card was added
      expect(find.text('Card Detected Offline'), findsNothing);
      expect(scannedCard, isNull);
    });

    testWidgets(
        'renders confirmation sheet with detected OCR details and saves valid card',
        (WidgetTester tester) async {
      CardModel? scannedCard;

      await tester.pumpWidget(
        MaterialApp(
          home: CardScannerScreen(
            testOcrLines: const [
              'HDFC BANK',
              '4532 1122 3344 5566',
              'VALID THRU 11/28',
              'JOHN DOE',
            ],
            onCardScanned: (card) {
              scannedCard = card;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the capture card button
      await tester.tap(find.byKey(const Key('capture_card_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify confirmation sheet appears with detected card details
      expect(find.text('Card Detected Offline'), findsOneWidget);
      expect(find.byKey(const Key('scanned_number_field')), findsOneWidget);
      expect(find.text('4532 1122 3344 5566'), findsOneWidget);

      // Enter nickname if needed
      await tester.enterText(
          find.byKey(const Key('scanned_nickname_field')), 'Celesta');
      await tester.pump();

      // Save card to stack
      await tester.tap(find.byKey(const Key('save_scanned_card_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify onCardScanned was called with valid detected card
      expect(scannedCard, isNotNull);
      expect(scannedCard!.cardNumber, '4532 1122 3344 5566');
      expect(scannedCard!.bankName, 'HDFC Bank');
    });
  });
}
