class InvoiceItem {
  final int id;
  final int invoiceId;
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
  final double taxableValue;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
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
    required this.taxableValue,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.igstRate,
    required this.igstAmount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int,
      invoiceId: json['invoice_id'] as int? ?? json['invoiceId'] as int? ?? 0,
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
      taxableValue: (json['taxable_value'] as num? ?? json['taxableValue'] as num? ?? 0.0).toDouble(),
      cgstRate: (json['cgst_rate'] as num? ?? json['cgstRate'] as num? ?? 0.0).toDouble(),
      cgstAmount: (json['cgst_amount'] as num? ?? json['cgstAmount'] as num? ?? 0.0).toDouble(),
      sgstRate: (json['sgst_rate'] as num? ?? json['sgstRate'] as num? ?? 0.0).toDouble(),
      sgstAmount: (json['sgst_amount'] as num? ?? json['sgstAmount'] as num? ?? 0.0).toDouble(),
      igstRate: (json['igst_rate'] as num? ?? json['igstRate'] as num? ?? 0.0).toDouble(),
      igstAmount: (json['igst_amount'] as num? ?? json['igstAmount'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
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
      'taxable_value': taxableValue,
      'cgst_rate': cgstRate,
      'cgst_amount': cgstAmount,
      'sgst_rate': sgstRate,
      'sgst_amount': sgstAmount,
      'igst_rate': igstRate,
      'igst_amount': igstAmount,
    };
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
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
    double? taxableValue,
    double? cgstRate,
    double? cgstAmount,
    double? sgstRate,
    double? sgstAmount,
    double? igstRate,
    double? igstAmount,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
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
      taxableValue: taxableValue ?? this.taxableValue,
      cgstRate: cgstRate ?? this.cgstRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstRate: sgstRate ?? this.sgstRate,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstRate: igstRate ?? this.igstRate,
      igstAmount: igstAmount ?? this.igstAmount,
    );
  }
}
