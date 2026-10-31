import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/models/card_model.dart';
import 'package:card_stack/screens/card_detail_screen.dart';

void main() {
  const testCard = CardModel(
    id: 'card_001',
    nickname: 'HDFC Millennia',
    cardholderName: 'Rahul Sharma',
    bankName: 'HDFC Bank',
    cardType: 'credit',
    cardNetwork: 'Visa',
    cardNumber: 'XXXX XXXX XXXX 4567',
    expiryMonth: '12',
    expiryYear: '2028',
    cvv: '789',
    colorHex: '#2455C3',
  );

  group('CardDetailScreen Tests', () {
    testWidgets('renders all card details and copy options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CardDetailScreen(card: testCard),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & basic info
      expect(find.text('HDFC Millennia'), findsWidgets);
      expect(find.text('HDFC Bank'), findsWidgets);
      expect(find.text('XXXX XXXX XXXX 4567'), findsWidgets);
      expect(find.text('12/28'), findsWidgets);
      expect(find.text('Copy to Clipboard'), findsOneWidget);

      // Verify Copy Tiles exist
      expect(find.byKey(const Key('copy_number_tile')), findsOneWidget);
      expect(find.byKey(const Key('copy_expiry_tile')), findsOneWidget);
      expect(find.byKey(const Key('copy_cvv_tile')), findsOneWidget);

      // Tap copy card number
      final copyNumberTile = find.byKey(const Key('copy_number_tile'));
      final copyNumberButton = find.descendant(
        of: copyNumberTile,
        matching: find.byIcon(Icons.copy_rounded),
      );
      await tester.tap(copyNumberButton);
      await tester.pump();
      expect(find.text('Card Number copied to clipboard!'), findsOneWidget);

      // Tap copy expiry
      final copyExpiryTile = find.byKey(const Key('copy_expiry_tile'));
      final copyExpiryButton = find.descendant(
        of: copyExpiryTile,
        matching: find.byIcon(Icons.copy_rounded),
      );
      await tester.tap(copyExpiryButton);
      await tester.pump();
      expect(find.text('Expiry Date copied to clipboard!'), findsOneWidget);

      // Verify CVV toggle
      final copyCvvTile = find.byKey(const Key('copy_cvv_tile'));
      await tester.ensureVisible(copyCvvTile);
      await tester.pumpAndSettle();
      expect(find.text('•••'), findsOneWidget);
      final toggleCvvButton = find.descendant(
        of: copyCvvTile,
        matching: find.byIcon(Icons.visibility_rounded),
      );
      await tester.tap(toggleCvvButton);
      await tester.pump();
      expect(find.text('789'), findsOneWidget);
    });

    testWidgets('3-dot menu opens with Edit and Delete options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CardDetailScreen(card: testCard),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 3-dot menu exists
      final menuButton = find.byKey(const Key('card_detail_menu_button'));
      expect(menuButton, findsOneWidget);

      // Open menu
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Check popup menu items
      expect(find.text('Edit Card'), findsOneWidget);
      expect(find.text('Delete Card'), findsOneWidget);
    });

    testWidgets('Edit card updates details and calls onCardUpdated',
        (WidgetTester tester) async {
      CardModel? updatedCard;

      await tester.pumpWidget(
        MaterialApp(
          home: CardDetailScreen(
            card: testCard,
            onCardUpdated: (c) => updatedCard = c,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3-dot menu
      await tester.tap(find.byKey(const Key('card_detail_menu_button')));
      await tester.pumpAndSettle();

      // Tap 'Edit Card'
      await tester.tap(find.text('Edit Card'));
      await tester.pumpAndSettle();

      // Verify edit sheet opened
      expect(find.text('Edit Card'), findsOneWidget);
      expect(find.byKey(const Key('edit_nickname_field')), findsOneWidget);

      // Change nickname
      await tester.enterText(
        find.byKey(const Key('edit_nickname_field')),
        'Updated Regalia',
      );
      // Change bank name
      await tester.enterText(
        find.byKey(const Key('edit_bank_field')),
        'HDFC Premier',
      );

      // Save changes
      final saveBtn = find.byKey(const Key('save_edited_card_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Check onCardUpdated was called
      expect(updatedCard, isNotNull);
      expect(updatedCard!.nickname, 'Updated Regalia');
      expect(updatedCard!.bankName, 'HDFC Premier');

      // Verify detail screen reflects the new details immediately
      expect(find.text('Updated Regalia'), findsWidgets);
      expect(find.text('HDFC Premier'), findsWidgets);
      expect(find.text('Card updated successfully!'), findsOneWidget);
    });

    testWidgets('Delete card shows confirmation and calls onCardDeleted',
        (WidgetTester tester) async {
      String? deletedId;

      await tester.pumpWidget(
        MaterialApp(
          home: CardDetailScreen(
            card: testCard,
            onCardDeleted: (id) => deletedId = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3-dot menu
      await tester.tap(find.byKey(const Key('card_detail_menu_button')));
      await tester.pumpAndSettle();

      // Tap 'Delete Card'
      await tester.tap(find.text('Delete Card'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Card'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "${testCard.nickname}"? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Tap 'Cancel' first to ensure it doesn't delete
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deletedId, isNull);

      // Open menu again & confirm delete
      await tester.tap(find.byKey(const Key('card_detail_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Card'));
      await tester.pumpAndSettle();

      // Tap 'Delete' button in dialog
      await tester.tap(find.byKey(const Key('confirm_delete_button')));
      await tester.pumpAndSettle();

      // Verify onCardDeleted was called
      expect(deletedId, 'card_001');
    });
  });
}
