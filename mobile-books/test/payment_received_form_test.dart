import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/invoices/presentation/screens/payment_received_form_screen.dart';

void main() {
  testWidgets('PaymentReceivedFormScreen renders form fields exactly once', (WidgetTester tester) async {
    // Set larger screen size so lazy list view builds all elements
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PaymentReceivedFormScreen(invoiceId: 0, balanceDue: 0.0),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title is rendered
    expect(find.text('Record Payment'), findsOneWidget);

    // Verify Amount Received is rendered
    expect(find.text('Amount Received *'), findsOneWidget);

    // Verify Notes label is rendered exactly once
    expect(find.text('Notes (Internal use. Not visible to customer)'), findsOneWidget);
  });
}

