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

class Payment {
  final int id;
  final int userId;
  final int invoiceId;
  final int? customerId;
  final double amount;
  final DateTime paymentDate;
  final String? paymentMode;
  final String? reference;
  final String? notes;
  final String status; // 'received' etc.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? customerName;  // Add helper for full list view
  final String? invoiceNumber; // Add helper for full list view

  Payment({
    required this.id,
    required this.userId,
    required this.invoiceId,
    this.customerId,
    required this.amount,
    required this.paymentDate,
    this.paymentMode,
    this.reference,
    this.notes,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.invoiceNumber,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? _parseInt(json['userId']) ?? 0,
      invoiceId: _parseInt(json['invoice_id']) ?? _parseInt(json['invoiceId']) ?? 0,
      customerId: _parseInt(json['customer_id']) ?? _parseInt(json['customerId']),
      amount: _parseDouble(json['amount']),
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      paymentMode: json['payment_mode'] as String? ?? json['paymentMode'] as String?,
      reference: json['reference'] as String? ?? json['reference_number'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'received',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      customerName: json['customer_name'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'invoice_id': invoiceId,
      'customer_id': customerId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_mode': paymentMode,
      'reference': reference,
      'notes': notes,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customer_name': customerName,
      'invoice_number': invoiceNumber,
    };
  }

  Payment copyWith({
    int? id,
    int? userId,
    int? invoiceId,
    int? customerId,
    double? amount,
    DateTime? paymentDate,
    String? paymentMode,
    String? reference,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? invoiceNumber,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMode: paymentMode ?? this.paymentMode,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    );
  }
}
