import 'package:fastswipe/app.dart';
import 'package:fastswipe/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen and routes to customer home on login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      FastSwipeApp(authRepository: MockAuthRepository()),
    );

    expect(find.text('FastSwipe login'), findsOneWidget);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Customer home — browse restaurants'), findsOneWidget);
  });
}
