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

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as int,
      itemId: json['item_id'] as int? ?? json['itemId'] as int? ?? 0,
      itemName: json['item_name'] as String? ?? json['itemName'] as String?,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      transactionType: json['transaction_type'] as String? ?? json['transactionType'] as String? ?? json['movement_type'] as String? ?? 'adjustment',
      quantityChange: _parseDouble(json['quantity_change'] ?? json['quantityChange'] ?? json['quantity']) ?? 0.0,
      referenceNumber: json['reference_number'] as String? ?? json['referenceNumber'] as String?,
      entryDate: json['entry_date'] != null 
          ? DateTime.tryParse(json['entry_date'] as String) 
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      description: json['description'] as String? ?? json['reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      previousStock: _parseDouble(json['previous_stock'] ?? json['previousStock']),
      newStock: _parseDouble(json['new_stock'] ?? json['newStock']),
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
