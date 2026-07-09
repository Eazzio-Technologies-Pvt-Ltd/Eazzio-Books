import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/sales_orders/presentation/screens/sales_order_form_screen.dart';

void main() {
  testWidgets('SalesOrderFormScreen renders Notes & Terms and Grand Total', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SalesOrderFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find Notes & Terms text and see how many times it is rendered
    final notesAndTermsFinder = find.text('Notes & Terms');
    print('Notes & Terms count: ${notesAndTermsFinder.evaluate().length}');
    
    final grandTotalFinder = find.text('Grand Total');
    print('Grand Total count: ${grandTotalFinder.evaluate().length}');
  });
}
