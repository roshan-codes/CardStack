import 'package:card_stack/main.dart';
import 'package:card_stack/widgets/liquid_glass_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neopop/neopop.dart';

void main() {
  testWidgets(
      'CardStackApp renders LiquidGlassBar with Home, Categories, Backup, Settings tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardStackApp(initiallyAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Verify LiquidGlassBar is present
    expect(find.byType(LiquidGlassBar), findsOneWidget);

    // 2. Verify all 4 tab labels are present: Home, Categories, Backup, Settings
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // 3. Verify FAB exists with 'Add Card' tooltip
    final fab = find.byKey(const Key('add_card_fab'));
    expect(fab, findsOneWidget);

    // 4. Tap Categories tab (index 1) -> Categories view with dynamic card types
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add_card_category_button')), findsOneWidget);
    expect(find.text('Credit Cards'), findsOneWidget);
    expect(find.text('Debit Cards'), findsOneWidget);
    expect(find.text('Prepaid Cards'), findsOneWidget);
    expect(find.text('ATM Cards'), findsOneWidget);
    expect(find.text('Other Cards'), findsOneWidget);

    // Tap on Credit Cards to verify bottom sheet opens
    await tester.tap(find.text('Credit Cards'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    // Dismiss bottom sheet
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // 5. Tap Backup tab (index 2) -> Google Drive backup view
    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();
    expect(find.text('Export to Google Drive'), findsOneWidget);
    expect(find.text('Restore from Google Drive'), findsOneWidget);
    expect(find.byKey(const Key('export_google_drive_button')), findsOneWidget);
    expect(find.byKey(const Key('restore_google_drive_button')), findsOneWidget);

    // 6. Tap Settings tab (index 3) -> Settings view
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('SECURITY & PREFERENCES'), findsOneWidget);
    expect(find.text('Biometric Unlock'), findsOneWidget);
    expect(find.text('Mask Sensitive Details'), findsOneWidget);
    expect(find.text('Haptic Feedback'), findsOneWidget);
    expect(find.text('Clear All Cards'), findsNothing);
    expect(find.byKey(const Key('reset_vault_button')), findsNothing);
    expect(find.text('CardStack v1.0.0'), findsOneWidget);

    // Toggle a setting switch
    await tester.tap(find.byKey(const Key('setting_biometric_switch')));
    await tester.pumpAndSettle();

    // 7. Tap Home tab (index 0) to return to main card stack
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('CardStack'), findsOneWidget);

    // 8. Tap FAB to open AddCardScreen
    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.text('ADD CARD'), findsOneWidget);
    expect(find.byKey(const Key('submit_add_card_button')), findsOneWidget);
    expect(find.byType(NeoPopButton), findsOneWidget);
  });
}
