import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/vendor_credits/presentation/screens/vendor_credit_form_screen.dart';

void main() {
  testWidgets('VendorCreditFormScreen renders form fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: VendorCreditFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title is rendered
    expect(find.text('New Vendor Credit'), findsOneWidget);
  });
}
