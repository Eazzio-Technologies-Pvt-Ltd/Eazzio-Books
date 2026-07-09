import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice_item.dart';

void main() {
  test('RecurringInvoice serialization', () {
    final ri = RecurringInvoice(
      id: 0,
      userId: 1,
      recurringInvoiceNumber: 'REC-00001',
      profileName: 'Test Profile',
      customerId: 2,
      frequency: 'Monthly',
      startDate: DateTime(2026, 7, 9),
      status: 'Active',
      subtotal: 100.0,
      discountTotal: 0.0,
      taxTotal: 18.0,
      total: 118.0,
      autoSendEmail: false,
    );

    final json = ri.toJson();
    expect(json['profile_name'], 'Test Profile');
    expect(json['customer_id'], 2);
    expect(json['frequency'], 'Monthly');
    expect(json['start_date'], '2026-07-09');
  });
}
