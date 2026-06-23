int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

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
      id: _parseInt(json['id']) ?? 0,
      invoiceId: _parseInt(json['invoice_id']) ?? _parseInt(json['invoiceId']) ?? 0,
      itemId: _parseInt(json['item_id']) ?? _parseInt(json['itemId']),
      itemName: json['item_name'] as String? ?? json['itemName'] as String?,
      hsnCode: json['hsn_code'] as String? ?? json['hsnCode'] as String?,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      quantity: _parseDouble(json['quantity']),
      unitPrice: _parseDouble(json['unit_price'] ?? json['unitPrice']),
      taxRate: _parseDouble(json['tax_rate'] ?? json['taxRate']),
      discount: _parseDouble(json['discount']),
      discountType: json['discount_type'] as String? ?? json['discountType'] as String? ?? 'flat',
      total: _parseDouble(json['total']),
      taxableValue: _parseDouble(json['taxable_value'] ?? json['taxableValue']),
      cgstRate: _parseDouble(json['cgst_rate'] ?? json['cgstRate']),
      cgstAmount: _parseDouble(json['cgst_amount'] ?? json['cgstAmount']),
      sgstRate: _parseDouble(json['sgst_rate'] ?? json['sgstRate']),
      sgstAmount: _parseDouble(json['sgst_amount'] ?? json['sgstAmount']),
      igstRate: _parseDouble(json['igst_rate'] ?? json['igstRate']),
      igstAmount: _parseDouble(json['igst_amount'] ?? json['igstAmount']),
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
