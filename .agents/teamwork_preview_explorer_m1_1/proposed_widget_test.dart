// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eazzio_books_mobile/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EazzioBooksApp(),
      ),
    );

    // Allow any initial animations or navigation to complete
    await tester.pumpAndSettle();

    // Verify that the login screen is displayed by finding branding text
    expect(find.text('Eazzio Books'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
