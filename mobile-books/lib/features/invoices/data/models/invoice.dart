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

class Invoice {
  final int id;
  final int customerId;
  final int userId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String status; // 'draft', 'sent', 'unpaid', 'partially_paid', 'paid', 'overdue', 'cancelled'
  final String? notes;
  final String? terms;
  final double totalAmount;
  final double balanceDue;
  final int? salespersonId;
  final int? projectId;
  final int? organizationId;
  final int? quoteId;
  final String? supplierState;
  final String? placeOfSupply;
  final String? customerGstin;
  final String? gstType; // 'intra_state' or 'inter_state'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.status,
    this.notes,
    this.terms,
    required this.totalAmount,
    required this.balanceDue,
    this.salespersonId,
    this.projectId,
    this.organizationId,
    this.quoteId,
    this.supplierState,
    this.placeOfSupply,
    this.customerGstin,
    this.gstType,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: _parseInt(json['id']) ?? 0,
      customerId: _parseInt(json['customer_id']) ?? _parseInt(json['customerId']) ?? 0,
      userId: _parseInt(json['user_id']) ?? _parseInt(json['userId']) ?? 0,
      invoiceNumber: json['invoice_number'] as String? ?? json['invoiceNumber'] as String? ?? 'DRAFT',
      invoiceDate: json['invoice_date'] != null
          ? DateTime.tryParse(json['invoice_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']),
      balanceDue: _parseDouble(json['balance_due'] ?? json['balanceDue']),
      salespersonId: _parseInt(json['salesperson_id']) ?? _parseInt(json['salespersonId']),
      projectId: _parseInt(json['project_id']) ?? _parseInt(json['projectId']),
      organizationId: _parseInt(json['organization_id']) ?? _parseInt(json['organizationId']),
      quoteId: _parseInt(json['quote_id']) ?? _parseInt(json['quoteId']),
      supplierState: json['supplier_state'] as String? ?? json['supplierState'] as String?,
      placeOfSupply: json['place_of_supply'] as String? ?? json['placeOfSupply'] as String?,
      customerGstin: json['customer_gstin'] as String? ?? json['customerGstin'] as String?,
      gstType: json['gst_type'] as String? ?? json['gstType'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'user_id': userId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'status': status,
      'notes': notes,
      'terms': terms,
      'total_amount': totalAmount,
      'balance_due': balanceDue,
      'salesperson_id': salespersonId,
      'project_id': projectId,
      'organization_id': organizationId,
      'quote_id': quoteId,
      'supplier_state': supplierState,
      'place_of_supply': placeOfSupply,
      'customer_gstin': customerGstin,
      'gst_type': gstType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Invoice copyWith({
    int? id,
    int? customerId,
    int? userId,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? status,
    String? notes,
    String? terms,
    double? totalAmount,
    double? balanceDue,
    int? salespersonId,
    int? projectId,
    int? organizationId,
    int? quoteId,
    String? supplierState,
    String? placeOfSupply,
    String? customerGstin,
    String? gstType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      totalAmount: totalAmount ?? this.totalAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      salespersonId: salespersonId ?? this.salespersonId,
      projectId: projectId ?? this.projectId,
      organizationId: organizationId ?? this.organizationId,
      quoteId: quoteId ?? this.quoteId,
      supplierState: supplierState ?? this.supplierState,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      customerGstin: customerGstin ?? this.customerGstin,
      gstType: gstType ?? this.gstType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
