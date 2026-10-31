import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/models/card_model.dart';
import 'package:card_stack/screens/add_card_screen.dart';

void main() {
  group('AddCardScreen Realtime UI Tests', () {
    testWidgets('updates card in realtime as user types and submits',
        (WidgetTester tester) async {
      CardModel? addedCard;

      await tester.pumpWidget(
        MaterialApp(
          home: AddCardScreen(
            onCardAdded: (card) {
              addedCard = card;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial preview card state
      expect(find.text('XXXX XXXX XXXX XXXX'), findsOneWidget);
      expect(find.text('Card Holder'), findsOneWidget);
      expect(find.text('08/2022'), findsOneWidget);

      // 1. Enter card number and verify realtime update
      final cardNumberField = find.widgetWithText(TextFormField, 'Card Number');
      await tester.enterText(cardNumberField, '5241123456789012');
      await tester.pump();

      expect(find.text('5241 1234 5678 9012'), findsWidgets);

      // 2. Enter full name and verify realtime update
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      await tester.enterText(nameField, 'Jane Doe');
      await tester.pump();

      expect(find.text('Jane Doe'), findsWidgets);

      // 3. Enter MM/YY expiry and verify realtime update
      final expiryField = find.widgetWithText(TextFormField, 'MM/YY');
      await tester.enterText(expiryField, '1128');
      await tester.pump();

      expect(find.text('11/28'), findsWidgets);

      // 4. Enter CVV
      final cvvField = find.widgetWithText(TextFormField, 'CVV');
      await tester.enterText(cvvField, '456');
      await tester.pump();

      // 5. Submit card
      final submitButton = find.byKey(const Key('submit_add_card_button'));
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(addedCard, isNotNull);
      expect(addedCard!.cardNumber, '5241 1234 5678 9012');
      expect(addedCard!.cardholderName, 'Jane Doe');
      expect(addedCard!.expiryMonth, '11');
      expect(addedCard!.expiryYear, '2028');
    });

    testWidgets('small scan option in card number field launches scanner',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddCardScreen(
            onCardAdded: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the small scan option inside the Card Number field
      final scanButton = find.byKey(const Key('scan_card_number_button'));
      expect(scanButton, findsOneWidget);

      // Tap scan button
      await tester.tap(scanButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify CardScannerScreen appears
      expect(find.text('Scan Payment Card'), findsOneWidget);
      expect(find.text('Offline Card Scanner'), findsOneWidget);
    });
  });
}
