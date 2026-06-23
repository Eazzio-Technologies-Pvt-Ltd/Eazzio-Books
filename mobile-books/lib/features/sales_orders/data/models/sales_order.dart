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

class SalesOrder {
  final int id;
  final int customerId;
  final int userId;
  final int? quoteId;
  final String salesOrderNumber;
  final DateTime salesOrderDate;
  final DateTime? expectedShipmentDate;
  final String? referenceNumber;
  final String status; // 'draft', 'confirmed', 'invoiced', 'cancelled'
  final String? notes;
  final String? terms;
  final double total;
  final int? salespersonId;
  final int? projectId;
  final String? discountType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalesOrder({
    required this.id,
    required this.customerId,
    required this.userId,
    this.quoteId,
    required this.salesOrderNumber,
    required this.salesOrderDate,
    this.expectedShipmentDate,
    this.referenceNumber,
    required this.status,
    this.notes,
    this.terms,
    required this.total,
    this.salespersonId,
    this.projectId,
    this.discountType,
    this.createdAt,
    this.updatedAt,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: _parseInt(json['id']) ?? 0,
      customerId: _parseInt(json['customer_id']) ?? _parseInt(json['customerId']) ?? 0,
      userId: _parseInt(json['user_id']) ?? _parseInt(json['userId']) ?? 0,
      quoteId: _parseInt(json['quote_id']) ?? _parseInt(json['quoteId']),
      salesOrderNumber: json['sales_order_number'] as String? ?? json['salesOrderNumber'] as String? ?? 'DRAFT',
      salesOrderDate: json['sales_order_date'] != null
          ? DateTime.tryParse(json['sales_order_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      expectedShipmentDate: json['expected_shipment_date'] != null
          ? DateTime.tryParse(json['expected_shipment_date'] as String)
          : null,
      referenceNumber: json['reference_number'] as String? ?? json['referenceNumber'] as String?,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      total: _parseDouble(json['total']),
      salespersonId: _parseInt(json['salesperson_id']) ?? _parseInt(json['salespersonId']),
      projectId: _parseInt(json['project_id']) ?? _parseInt(json['projectId']),
      discountType: json['discount_type'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'user_id': userId,
      'quote_id': quoteId,
      'sales_order_number': salesOrderNumber,
      'sales_order_date': salesOrderDate.toIso8601String().split('T')[0],
      'expected_shipment_date': expectedShipmentDate?.toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
      'status': status,
      'notes': notes,
      'terms': terms,
      'total': total,
      'salesperson_id': salespersonId,
      'project_id': projectId,
      'discount_type': discountType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SalesOrder copyWith({
    int? id,
    int? customerId,
    int? userId,
    int? quoteId,
    String? salesOrderNumber,
    DateTime? salesOrderDate,
    DateTime? expectedShipmentDate,
    String? referenceNumber,
    String? status,
    String? notes,
    String? terms,
    double? total,
    int? salespersonId,
    int? projectId,
    String? discountType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      quoteId: quoteId ?? this.quoteId,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      salesOrderDate: salesOrderDate ?? this.salesOrderDate,
      expectedShipmentDate: expectedShipmentDate ?? this.expectedShipmentDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      total: total ?? this.total,
      salespersonId: salespersonId ?? this.salespersonId,
      projectId: projectId ?? this.projectId,
      discountType: discountType ?? this.discountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
