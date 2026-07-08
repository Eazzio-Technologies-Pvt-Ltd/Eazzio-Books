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
    double _d(dynamic v) => v != null ? double.tryParse(v.toString()) ?? 0.0 : 0.0;
    return RecurringInvoiceItem(
      id: json['id'] as int?,
      recurringInvoiceId: json['recurring_invoice_id'] as int? ?? json['recurringInvoiceId'] as int?,
      itemId: json['item_id'] as int? ?? json['itemId'] as int?,
      itemName: json['item_name'] as String? ?? json['itemName'] as String? ?? '',
      description: json['description'] as String?,
      quantity: _d(json['quantity']) == 0.0 ? 1.0 : _d(json['quantity']),
      rate: _d(json['rate']),
      discount: _d(json['discount']),
      taxRate: _d(json['tax_rate']),
      taxAmount: _d(json['tax_amount']),
      lineTotal: _d(json['line_total']),
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
