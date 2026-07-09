import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit_item.dart';

void main() {
  test('VendorCredit items serialization matching backend keys', () {
    final item = VendorCreditItem(
      id: 0,
      vendorCreditId: 0,
      itemId: 42,
      itemName: 'Blue Pen',
      description: 'A blue pen',
      quantity: 2.0,
      rate: 10.0,
      discount: 0.0,
      discountType: 'flat',
      taxRate: 18.0,
      taxAmount: 3.6,
      lineTotal: 23.6,
    );

    final map = item.toJson();
    expect(map['item_id'], 42);
    expect(map['item_name'], 'Blue Pen');
    expect(map['quantity'], 2.0);
    expect(map['rate'], 10.0);
    expect(map['discount'], 0.0);
    expect(map['discount_type'], 'flat');
    expect(map['tax_rate'], 18.0);
  });
}
