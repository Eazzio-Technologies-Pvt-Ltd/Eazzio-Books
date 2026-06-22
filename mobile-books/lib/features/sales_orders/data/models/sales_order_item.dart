class SalesOrderItem {
  final int id;
  final int salesOrderId;
  final int? itemId;
  final String? itemName; // Snapshot field
  final String? hsnCode;  // Snapshot field
  final String? unit;     // Snapshot field
  final String? description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double discount;
  final String discountType; // 'flat' or 'percent'
  final double total;

  SalesOrderItem({
    required this.id,
    required this.salesOrderId,
    this.itemId,
    this.itemName,
    this.hsnCode,
    this.unit,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.discount,
    required this.discountType,
    required this.total,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      id: json['id'] as int,
      salesOrderId: json['sales_order_id'] as int? ?? json['salesOrderId'] as int? ?? 0,
      itemId: json['item_id'] as int? ?? json['itemId'] as int?,
      itemName: json['item_name'] as String? ?? json['itemName'] as String?,
      hsnCode: json['hsn_code'] as String? ?? json['hsnCode'] as String?,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num? ?? 1.0).toDouble(),
      unitPrice: (json['unit_price'] as num? ?? json['unitPrice'] as num? ?? 0.0).toDouble(),
      taxRate: (json['tax_rate'] as num? ?? json['taxRate'] as num? ?? 0.0).toDouble(),
      discount: (json['discount'] as num? ?? 0.0).toDouble(),
      discountType: json['discount_type'] as String? ?? json['discountType'] as String? ?? 'flat',
      total: (json['total'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sales_order_id': salesOrderId,
      'item_id': itemId,
      'item_name': itemName,
      'hsn_code': hsnCode,
      'unit': unit,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'discount': discount,
      'discount_type': discountType,
      'total': total,
    };
  }

  SalesOrderItem copyWith({
    int? id,
    int? salesOrderId,
    int? itemId,
    String? itemName,
    String? hsnCode,
    String? unit,
    String? description,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    double? discount,
    String? discountType,
    double? total,
  }) {
    return SalesOrderItem(
      id: id ?? this.id,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      total: total ?? this.total,
    );
  }
}
