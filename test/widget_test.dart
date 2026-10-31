import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/main.dart';

void main() {
  testWidgets('CardStack renders My Cards screen, handles add and details',
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
    expect(find.text('Search cards, bank or type...'), findsOneWidget);

    // Verify first card
    expect(find.text('HDFC Millennia'), findsOneWidget);
    expect(find.text('XXXX XXXX XXXX 4567'), findsOneWidget);

    // Tap the Add Card button (+)
    final addButton = find.byTooltip('Add Card');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify AddCardScreen opens directly
    expect(find.text('ADD CARD'), findsOneWidget);
    expect(find.byKey(const Key('submit_add_card_button')), findsOneWidget);
    expect(find.byKey(const Key('scan_card_number_button')), findsOneWidget);

    // Tap back button to return to wallet
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Tap first card to open details
    await tester.tap(find.text('HDFC Millennia'));
    await tester.pumpAndSettle();

    // Verify on CardDetailScreen
    expect(find.text('Copy to Clipboard'), findsOneWidget);
    expect(find.byKey(const Key('copy_number_tile')), findsOneWidget);

    // Tap back button to return to wallet
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('CardStack'), findsOneWidget);
  });

  testWidgets('Search bar and filter tabs filter cards in realtime',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardStackApp(initiallyAuthenticated: true));
    await tester.pumpAndSettle();

    // Initially both HDFC and ICICI cards are present
    expect(find.text('HDFC Millennia'), findsOneWidget);
    expect(find.text('ICICI Amazon Pay'), findsOneWidget);

    // Verify search field is always present
    final searchField = find.byKey(const Key('bank_search_text_field'));
    expect(searchField, findsOneWidget);

    // Type "HDFC" to filter by bank name
    await tester.enterText(searchField, 'HDFC');
    await tester.pumpAndSettle();

    // Verify HDFC cards are displayed, non-HDFC are filtered out
    expect(find.text('HDFC Millennia'), findsOneWidget);
    expect(find.text('HDFC Salary Account'), findsOneWidget);
    expect(find.text('ICICI Amazon Pay'), findsNothing);
    expect(find.text('Axis Flipkart'), findsNothing);

    // Type non-existing bank name "Citibank"
    await tester.enterText(searchField, 'Citibank');
    await tester.pumpAndSettle();
    expect(find.text('No cards found for "Citibank"'), findsOneWidget);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    // Verify all cards return
    expect(find.text('HDFC Millennia'), findsOneWidget);
    expect(find.text('ICICI Amazon Pay'), findsOneWidget);

    // Test filter tabs: tap "Debit"
    await tester.tap(find.byKey(const Key('filter_tab_debit')));
    await tester.pumpAndSettle();

    // Verify only debit cards shown
    expect(find.text('HDFC Salary Account'), findsOneWidget);
    expect(find.text('HDFC Millennia'), findsNothing);

    // Return to "All"
    await tester.tap(find.byKey(const Key('filter_tab_all')));
    await tester.pumpAndSettle();
    expect(find.text('HDFC Millennia'), findsOneWidget);
  });
}
