import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stack/screens/auth_guard_screen.dart';
import 'package:card_stack/services/auth_service.dart';

class FakeAuthService extends AuthService {
  final bool shouldSucceed;
  int authCalls = 0;

  FakeAuthService({this.shouldSucceed = true});

  @override
  Future<bool> authenticate({String reason = ''}) async {
    authCalls++;
    return shouldSucceed;
  }
}

void main() {
  group('AuthGuardScreen Tests', () {
    testWidgets('displays locked screen when not authenticated', (tester) async {
      final fakeAuth = FakeAuthService(shouldSucceed: false);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGuardScreen(
            authService: fakeAuth,
            autoPrompt: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CardStack Locked'), findsOneWidget);
      expect(find.text('Unlock CardStack'), findsOneWidget);
    });

    testWidgets('unlocks and shows content upon successful authentication', (tester) async {
      final fakeAuth = FakeAuthService(shouldSucceed: true);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGuardScreen(
            authService: fakeAuth,
            autoPrompt: false,
            destination: const Scaffold(
              body: Center(child: Text('Unlocked Content')),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap unlock button
      await tester.tap(find.text('Unlock CardStack'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeAuth.authCalls, 1);
      expect(find.text('Unlocked Content'), findsOneWidget);
    });

    testWidgets('shows retry error message if authentication fails', (tester) async {
      final fakeAuth = FakeAuthService(shouldSucceed: false);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGuardScreen(
            authService: fakeAuth,
            autoPrompt: false,
          ),
        ),
      );
      await tester.pump();

      // Tap unlock button
      await tester.tap(find.text('Unlock CardStack'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Authentication canceled or failed. Tap below to retry.'), findsOneWidget);
    });
  });
}
