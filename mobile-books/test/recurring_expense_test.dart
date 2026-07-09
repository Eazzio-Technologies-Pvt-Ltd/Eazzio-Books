import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/recurring_expenses/presentation/screens/recurring_expense_form_screen.dart';

void main() {
  testWidgets('RecurringExpenseFormScreen renders form fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RecurringExpenseFormScreen(),
        ),
      ),
    );

    // Let's pump and see if it throws any build exceptions
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('New Recurring Expense'), findsOneWidget);
    // Verify some of the form fields
    expect(find.text('Expense Name *'), findsOneWidget);
    expect(find.text('Amount (₹) *'), findsOneWidget);
    expect(find.text('Due Day (1-31) *'), findsOneWidget);
  });
}
