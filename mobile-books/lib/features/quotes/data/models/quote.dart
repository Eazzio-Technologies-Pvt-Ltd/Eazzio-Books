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
    this.createdAt,
    this.updatedAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int,
      customerId: json['customer_id'] as int? ?? json['customerId'] as int? ?? 0,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      quoteNumber: json['quote_number'] as String? ?? json['quoteNumber'] as String? ?? 'DRAFT',
      quoteDate: json['quote_date'] != null
          ? DateTime.tryParse(json['quote_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'] as String) : null,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      totalAmount: (json['total_amount'] as num? ?? json['totalAmount'] as num? ?? 0.0).toDouble(),
      salespersonId: json['salesperson_id'] as int? ?? json['salespersonId'] as int?,
      projectId: json['project_id'] as int? ?? json['projectId'] as int?,
      organizationId: json['organization_id'] as int? ?? json['organizationId'] as int?,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
