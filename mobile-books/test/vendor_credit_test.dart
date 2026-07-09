import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit.dart';

void main() {
  test('VendorCredit serialization', () {
    final vc = VendorCredit(
      id: 0,
      userId: 1,
      vendorId: 2,
      vendorCreditNumber: 'VC-001',
      vendorCreditDate: DateTime(2026, 7, 9),
      status: 'Open',
      subtotal: 100.0,
      discountTotal: 0.0,
      taxTotal: 18.0,
      total: 118.0,
      appliedAmount: 0.0,
      remainingAmount: 118.0,
    );

    final json = vc.toJson();
    expect(json['vendor_credit_number'], 'VC-001');
    expect(json['total'], 118.0);
    expect(json['remaining_amount'], 118.0);
  });
}
