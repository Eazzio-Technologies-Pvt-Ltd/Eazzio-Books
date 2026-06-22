class BillItem {
  final int? id;
  final int? billId;
  final int? itemId;
  final String itemName;
  final String? description;
  final String? hsnCode;
  final String? unit;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final double total;

  BillItem({
    this.id,
    this.billId,
    this.itemId,
    required this.itemName,
    this.description,
    this.hsnCode,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.taxRate = 0.0,
    required this.total,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as int?,
      billId: json['bill_id'] as int? ?? json['billId'] as int?,
      itemId: json['item_id'] as int? ?? json['itemId'] as int?,
      itemName: json['item_name'] as String? ?? json['itemName'] as String? ?? '',
      description: json['description'] as String?,
      hsnCode: json['hsn_code'] as String? ?? json['hsnCode'] as String?,
      unit: json['unit'] as String?,
      quantity: json['quantity'] != null ? double.tryParse(json['quantity'].toString()) ?? 1.0 : 1.0,
      unitPrice: json['unit_price'] != null ? double.tryParse(json['unit_price'].toString()) ?? 0.0 : 0.0,
      discount: json['discount'] != null ? double.tryParse(json['discount'].toString()) ?? 0.0 : 0.0,
      taxRate: json['tax_rate'] != null ? double.tryParse(json['tax_rate'].toString()) ?? 0.0 : 0.0,
      total: json['total'] != null ? double.tryParse(json['total'].toString()) ?? 0.0 : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      'item_id': itemId,
      'item_name': itemName,
      'description': description,
      'hsn_code': hsnCode,
      'unit': unit,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'tax_rate': taxRate,
      'total': total,
    };
  }
}
