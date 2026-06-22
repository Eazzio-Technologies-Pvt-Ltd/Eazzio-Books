class InventoryMovement {
  final int id;
  final int itemId;
  final String? itemName;
  final int userId;
  final String? transactionType; // 'adjustment', 'initial_stock', etc.
  final double quantityChange;
  final String? referenceNumber;
  final DateTime? entryDate;
  final String? description;
  final DateTime? createdAt;
  final double? previousStock;
  final double? newStock;
  final String? notes;

  InventoryMovement({
    required this.id,
    required this.itemId,
    this.itemName,
    required this.userId,
    this.transactionType,
    required this.quantityChange,
    this.referenceNumber,
    this.entryDate,
    this.description,
    this.createdAt,
    this.previousStock,
    this.newStock,
    this.notes,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as int,
      itemId: json['item_id'] as int? ?? json['itemId'] as int? ?? 0,
      itemName: json['item_name'] as String? ?? json['itemName'] as String?,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      transactionType: json['transaction_type'] as String? ?? json['transactionType'] as String? ?? json['movement_type'] as String? ?? 'adjustment',
      quantityChange: (json['quantity_change'] as num? ?? json['quantityChange'] as num? ?? json['quantity'] as num? ?? 0.0).toDouble(),
      referenceNumber: json['reference_number'] as String? ?? json['referenceNumber'] as String?,
      entryDate: json['entry_date'] != null 
          ? DateTime.tryParse(json['entry_date'] as String) 
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      description: json['description'] as String? ?? json['reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      previousStock: json['previous_stock'] != null 
          ? (json['previous_stock'] as num).toDouble() 
          : (json['previousStock'] != null ? (json['previousStock'] as num).toDouble() : null),
      newStock: json['new_stock'] != null 
          ? (json['new_stock'] as num).toDouble() 
          : (json['newStock'] != null ? (json['newStock'] as num).toDouble() : null),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'user_id': userId,
      'transaction_type': transactionType,
      'quantity_change': quantityChange,
      'reference_number': referenceNumber,
      'entry_date': entryDate?.toIso8601String(),
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'previous_stock': previousStock,
      'new_stock': newStock,
      'notes': notes,
    };
  }
}
