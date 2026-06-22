class DeliveryChallanItem {
  final int? id;
  final int? deliveryChallanId;
  final int? itemId;
  final String itemName;
  final String? description;
  final double quantity;
  final String? unit;
  final double rate;
  final double lineTotal;

  DeliveryChallanItem({
    this.id,
    this.deliveryChallanId,
    this.itemId,
    required this.itemName,
    this.description,
    required this.quantity,
    this.unit,
    required this.rate,
    required this.lineTotal,
  });

  factory DeliveryChallanItem.fromJson(Map<String, dynamic> json) {
    return DeliveryChallanItem(
      id: json['id'] as int?,
      deliveryChallanId: json['delivery_challan_id'] as int? ?? json['deliveryChallanId'] as int?,
      itemId: json['item_id'] as int? ?? json['itemId'] as int?,
      itemName: json['item_name'] as String? ?? json['itemName'] as String? ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num? ?? 1.0).toDouble(),
      unit: json['unit'] as String?,
      rate: (json['rate'] as num? ?? 0.0).toDouble(),
      lineTotal: (json['line_total'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_challan_id': deliveryChallanId,
      'item_id': itemId,
      'item_name': itemName,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'line_total': lineTotal,
    };
  }
}
