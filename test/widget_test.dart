import 'package:fastswipe/app.dart';
import 'package:fastswipe/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'splash routes to OTP login, and OTP verification routes to the shop home',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        FastSwipeApp(authRepository: MockAuthRepository()),
      );

      expect(find.textContaining('Delivery'), findsWidgets);

      // Let the splash screen's intro timer elapse and the redirect fire.
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pump();

      expect(find.text('Welcome Back'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      final otpFields = find.byType(TextField);
      expect(otpFields, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        await tester.enterText(otpFields.at(i), '1');
      }

      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Daily Deals'), findsOneWidget);
    },
  );
}
