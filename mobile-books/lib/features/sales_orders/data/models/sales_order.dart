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
    this.createdAt,
    this.updatedAt,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'] as int,
      customerId: json['customer_id'] as int? ?? json['customerId'] as int? ?? 0,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      quoteId: json['quote_id'] as int? ?? json['quoteId'] as int?,
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
      total: (json['total'] as num? ?? 0.0).toDouble(),
      salespersonId: json['salesperson_id'] as int? ?? json['salespersonId'] as int?,
      projectId: json['project_id'] as int? ?? json['projectId'] as int?,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
