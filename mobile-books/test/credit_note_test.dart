import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_books/features/credit_notes/data/models/credit_note.dart';

void main() {
  test('CreditNote serialization', () {
    final cn = CreditNote(
      id: 0,
      userId: 1,
      customerId: 2,
      invoiceId: 3,
      creditNoteNumber: 'CN-001',
      creditNoteDate: DateTime(2026, 7, 9),
      status: 'Open',
      subtotal: 100.0,
      discountTotal: 0.0,
      taxTotal: 18.0,
      total: 118.0,
      appliedAmount: 0.0,
      remainingAmount: 118.0,
    );

    final json = cn.toJson();
    expect(json['credit_note_number'], 'CN-001');
    expect(json['credit_note_date'], '2026-07-09');
    expect(json['user_id'], 1);
  });
}
