class PurchaseOrderItem {
  final int? id;
  final int? purchaseOrderId;
  final int? itemId;
  final String itemName;
  final String? description;
  final String? hsnCode;
  final String? unit;
  final double quantity;
  final double rate;
  final double discount;
  final String discountType; // 'flat' or 'percent'/'percentage'
  final double taxRate;
  final double taxAmount;
  final double lineTotal;

  PurchaseOrderItem({
    this.id,
    this.purchaseOrderId,
    this.itemId,
    required this.itemName,
    this.description,
    this.hsnCode,
    this.unit,
    required this.quantity,
    required this.rate,
    this.discount = 0.0,
    this.discountType = 'flat',
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    required this.lineTotal,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'] as int?,
      purchaseOrderId: json['purchase_order_id'] as int? ?? json['purchaseOrderId'] as int?,
      itemId: json['item_id'] as int? ?? json['itemId'] as int?,
      itemName: json['item_name'] as String? ?? json['itemName'] as String? ?? '',
      description: json['description'] as String?,
      hsnCode: json['hsn_code'] as String? ?? json['hsnCode'] as String?,
      unit: json['unit'] as String?,
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
      if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
      'item_id': itemId,
      'item_name': itemName,
      'description': description,
      'hsn_code': hsnCode,
      'unit': unit,
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
