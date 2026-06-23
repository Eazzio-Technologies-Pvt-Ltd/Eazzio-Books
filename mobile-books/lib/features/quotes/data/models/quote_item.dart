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

class QuoteItem {
  final int id;
  final int quoteId;
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

  QuoteItem({
    required this.id,
    required this.quoteId,
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

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: _parseInt(json['id']) ?? 0,
      quoteId: _parseInt(json['quote_id']) ?? _parseInt(json['quoteId']) ?? 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
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

  QuoteItem copyWith({
    int? id,
    int? quoteId,
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
    return QuoteItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
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
