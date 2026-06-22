class RecurringInvoiceItem {
  final int? id;
  final int? recurringInvoiceId;
  final int? itemId;
  final String itemName;
  final String? description;
  final double quantity;
  final double rate;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final double lineTotal;

  RecurringInvoiceItem({
    this.id,
    this.recurringInvoiceId,
    this.itemId,
    required this.itemName,
    this.description,
    required this.quantity,
    required this.rate,
    required this.discount,
    required this.taxRate,
    required this.taxAmount,
    required this.lineTotal,
  });

  factory RecurringInvoiceItem.fromJson(Map<String, dynamic> json) {
    return RecurringInvoiceItem(
      id: json['id'] as int?,
      recurringInvoiceId: json['recurring_invoice_id'] as int? ?? json['recurringInvoiceId'] as int?,
      itemId: json['item_id'] as int? ?? json['itemId'] as int?,
      itemName: json['item_name'] as String? ?? json['itemName'] as String? ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num? ?? 1.0).toDouble(),
      rate: (json['rate'] as num? ?? 0.0).toDouble(),
      discount: (json['discount'] as num? ?? 0.0).toDouble(),
      taxRate: (json['tax_rate'] as num? ?? 0.0).toDouble(),
      taxAmount: (json['tax_amount'] as num? ?? 0.0).toDouble(),
      lineTotal: (json['line_total'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recurring_invoice_id': recurringInvoiceId,
      'item_id': itemId,
      'item_name': itemName,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'discount': discount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'line_total': lineTotal,
    };
  }
}
