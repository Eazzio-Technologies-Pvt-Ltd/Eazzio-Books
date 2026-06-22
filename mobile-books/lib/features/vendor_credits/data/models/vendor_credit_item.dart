class VendorCreditItem {
  final int? id;
  final int? vendorCreditId;
  final int? itemId;
  final String itemName;
  final String? description;
  final double quantity;
  final double rate;
  final double discount;
  final String discountType; // 'flat' or 'percent'
  final double taxRate;
  final double taxAmount;
  final double lineTotal;

  VendorCreditItem({
    this.id,
    this.vendorCreditId,
    this.itemId,
    required this.itemName,
    this.description,
    required this.quantity,
    required this.rate,
    this.discount = 0.0,
    this.discountType = 'flat',
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    required this.lineTotal,
  });

  factory VendorCreditItem.fromJson(Map<String, dynamic> json) {
    return VendorCreditItem(
      id: json['id'] as int?,
      vendorCreditId: json['vendor_credit_id'] as int? ?? json['vendorCreditId'] as int?,
      itemId: json['item_id'] as int? ?? json['itemId'] as int?,
      itemName: json['item_name'] as String? ?? json['itemName'] as String? ?? '',
      description: json['description'] as String?,
      quantity: json['quantity'] != null ? double.tryParse(json['quantity'].toString()) ?? 1.0 : 1.0,
      rate: json['rate'] != null ? double.tryParse(json['rate'].toString()) ?? 0.0 : 0.0,
      discount: json['discount'] != null ? double.tryParse(json['discount'].toString()) ?? 0.0 : 0.0,
      discountType: json['discount_type'] as String? ?? json['discountType'] as String? ?? 'flat',
      taxRate: json['tax_rate'] != null ? double.tryParse(json['tax_rate'].toString()) ?? 0.0 : 0.0,
      taxAmount: json['tax_amount'] != null ? double.tryParse(json['tax_amount'].toString()) ?? 0.0 : 0.0,
      lineTotal: json['line_total'] != null ? double.tryParse(json['line_total'].toString()) ?? 0.0 : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (vendorCreditId != null) 'vendor_credit_id': vendorCreditId,
      'item_id': itemId,
      'item_name': itemName,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'discount': discount,
      'discount_type': discountType,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'line_total': lineTotal,
    };
  }
}
