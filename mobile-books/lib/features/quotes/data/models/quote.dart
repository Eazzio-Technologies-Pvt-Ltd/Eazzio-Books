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

class Quote {
  final int id;
  final int customerId;
  final int userId;
  final String quoteNumber;
  final DateTime quoteDate;
  final DateTime? expiryDate;
  final String status; // 'draft', 'sent', 'accepted', 'declined', 'expired', 'invoiced'
  final String? notes;
  final String? terms;
  final double totalAmount;
  final int? salespersonId;
  final int? projectId;
  final int? organizationId;
  final double? adjustment;
  final String? discountType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quote({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.quoteNumber,
    required this.quoteDate,
    this.expiryDate,
    required this.status,
    this.notes,
    this.terms,
    required this.totalAmount,
    this.salespersonId,
    this.projectId,
    this.organizationId,
    this.adjustment,
    this.discountType,
    this.createdAt,
    this.updatedAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: _parseInt(json['id']) ?? 0,
      customerId: _parseInt(json['customer_id']) ?? _parseInt(json['customerId']) ?? 0,
      userId: _parseInt(json['user_id']) ?? _parseInt(json['userId']) ?? 0,
      quoteNumber: json['quote_number'] as String? ?? json['quoteNumber'] as String? ?? 'DRAFT',
      quoteDate: json['quote_date'] != null
          ? DateTime.tryParse(json['quote_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'] as String) : null,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']),
      salespersonId: _parseInt(json['salesperson_id']) ?? _parseInt(json['salespersonId']),
      projectId: _parseInt(json['project_id']) ?? _parseInt(json['projectId']),
      organizationId: _parseInt(json['organization_id']) ?? _parseInt(json['organizationId']),
      adjustment: json['adjustment'] != null ? _parseDouble(json['adjustment']) : null,
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
      'quote_number': quoteNumber,
      'quote_date': quoteDate.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'status': status,
      'notes': notes,
      'terms': terms,
      'total_amount': totalAmount,
      'salesperson_id': salespersonId,
      'project_id': projectId,
      'organization_id': organizationId,
      'adjustment': adjustment,
      'discount_type': discountType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Quote copyWith({
    int? id,
    int? customerId,
    int? userId,
    String? quoteNumber,
    DateTime? quoteDate,
    DateTime? expiryDate,
    String? status,
    String? notes,
    String? terms,
    double? totalAmount,
    int? salespersonId,
    int? projectId,
    int? organizationId,
    double? adjustment,
    String? discountType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      quoteDate: quoteDate ?? this.quoteDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      totalAmount: totalAmount ?? this.totalAmount,
      salespersonId: salespersonId ?? this.salespersonId,
      projectId: projectId ?? this.projectId,
      organizationId: organizationId ?? this.organizationId,
      adjustment: adjustment ?? this.adjustment,
      discountType: discountType ?? this.discountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
