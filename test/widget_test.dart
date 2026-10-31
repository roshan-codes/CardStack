import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/main.dart';

void main() {
  testWidgets('CardStack renders cards, handles add dialog, and locks app',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardStackApp(initiallyAuthenticated: true));
    await tester.pumpAndSettle();

    // Verify app title, hello greeting, and cards count badge
    expect(find.text('CardStack'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('10 Cards'), findsOneWidget);

    // Verify first card
    expect(find.text('HDFC Millennia'), findsOneWidget);
    expect(find.text('XXXX XXXX XXXX 4567'), findsOneWidget);

    // Tap the Add Card button in AppBar
    final addButton = find.byTooltip('Add Card');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify dialog appears in the center
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Add New Card'), findsOneWidget);
    expect(find.text('Scan Card'), findsOneWidget);
    expect(find.text('Add Card Manually'), findsOneWidget);

    // Tap Cancel to dismiss
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    // Tap first card to open details
    await tester.tap(find.text('HDFC Millennia'));
    await tester.pumpAndSettle();

    // Verify on CardDetailScreen
    expect(find.text('Copy to Clipboard'), findsOneWidget);
    expect(find.byKey(const Key('copy_number_tile')), findsOneWidget);

    // Tap back button to return to wallet
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('Search bar expands and filters cards by bank name',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardStackApp(initiallyAuthenticated: true));
    await tester.pumpAndSettle();

    // Initially both HDFC and ICICI cards are present
    expect(find.text('HDFC Millennia'), findsOneWidget);
    expect(find.text('ICICI Amazon Pay'), findsOneWidget);

    // Click Search icon in AppBar
    final searchButton = find.byTooltip('Search Cards');
    expect(searchButton, findsOneWidget);
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // Verify search text field appears
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

    // Close search
    final closeButton = find.byTooltip('Close Search');
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    // Verify search is collapsed and all cards return
    expect(find.text('HDFC Millennia'), findsOneWidget);
    expect(find.text('ICICI Amazon Pay'), findsOneWidget);
  });
}
