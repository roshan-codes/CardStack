import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/main.dart';

void main() {
  testWidgets('CardStack renders clean empty vault and adds a new card',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardStackApp(initiallyAuthenticated: true));
    await tester.pumpAndSettle();

    // Verify title "CardStack" and filter tabs
    expect(find.text('CardStack'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.text('Debit'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    // Verify search bar placeholder
    expect(find.text('Search cards or banks...'), findsOneWidget);

    // Verify clean initial vault shows empty state guidance
    expect(find.text('No Cards in Vault'), findsOneWidget);
    expect(find.byKey(const Key('add_first_card_button')), findsOneWidget);

    // Tap the Add Card button (+)
    final addButton = find.byTooltip('Add Card');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify AddCardScreen opens directly
    expect(find.text('ADD CARD'), findsOneWidget);
    expect(find.byKey(const Key('submit_add_card_button')), findsOneWidget);
    expect(find.byKey(const Key('scan_card_number_button')), findsOneWidget);

    // Enter details for a new card
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Card Number'), '4111 2222 3333 4444');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Alice Smith');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'MM/YY'), '1228');
    await tester.pump();

    // Submit card
    final submitButton = find.byKey(const Key('submit_add_card_button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify returned to wallet and new card is displayed
    expect(find.text('CardStack'), findsOneWidget);
    expect(find.text('4111 2222 3333 4444'), findsOneWidget);
  });

  testWidgets('Search bar and filter tabs filter cards dynamically',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardStackApp(initiallyAuthenticated: true));
    await tester.pumpAndSettle();

    // Add first card: Chase Freedom (Credit)
    final addButton = find.byTooltip('Add Card');
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Card Number'), '4111 2222 3333 4567');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Alice Smith');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'MM/YY'), '1228');
    await tester.pump();

    final bankField = find.byKey(const Key('edit_bank_field'));
    await tester.ensureVisible(bankField);
    await tester.pumpAndSettle();
    await tester.enterText(bankField, 'Chase');
    await tester.pump();

    final nicknameField = find.byKey(const Key('edit_nickname_field'));
    await tester.ensureVisible(nicknameField);
    await tester.pumpAndSettle();
    await tester.enterText(nicknameField, 'Chase Freedom');
    await tester.pump();

    final submitButton = find.byKey(const Key('submit_add_card_button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Chase Freedom'), findsOneWidget);

    // Verify search field filters dynamically
    final searchField = find.byKey(const Key('bank_search_text_field'));
    expect(searchField, findsOneWidget);

    // Type "Chase"
    await tester.enterText(searchField, 'Chase');
    await tester.pumpAndSettle();
    expect(find.text('Chase Freedom'), findsOneWidget);

    // Type "NonExisting"
    await tester.enterText(searchField, 'NonExisting');
    await tester.pumpAndSettle();
    expect(find.text('No cards found for "NonExisting"'), findsOneWidget);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();
    expect(find.text('Chase Freedom'), findsOneWidget);
  });
}
