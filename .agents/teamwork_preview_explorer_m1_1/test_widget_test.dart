import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eazzio_books_mobile/main.dart';
import 'proposed_api_service.dart';

void main() {
  test('ApiService static fields check', () {
    expect(ApiService.appMode, equals('development'));
    expect(ApiService.apiBaseUrl, equals(''));
  });

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
