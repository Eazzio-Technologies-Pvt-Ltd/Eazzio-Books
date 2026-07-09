import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/recurring_expenses/presentation/screens/recurring_expense_form_screen.dart';

void main() {
  testWidgets('RecurringExpenseFormScreen build test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RecurringExpenseFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('New Recurring Expense'), findsOneWidget);
  });
}
