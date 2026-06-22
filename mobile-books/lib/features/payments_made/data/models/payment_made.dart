class PaymentMade {
  final int id;
  final int userId;
  final int billId;
  final int? vendorId;
  final String? vendorName;
  final String? billNumber;
  final double amount;
  final DateTime paymentDate;
  final String? paymentMode; // e.g. Cash, Bank Transfer, Check
  final String? referenceNumber;
  final String? notes;
  final String status; // 'paid', 'void'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentMade({
    required this.id,
    required this.userId,
    required this.billId,
    this.vendorId,
    this.vendorName,
    this.billNumber,
    required this.amount,
    required this.paymentDate,
    this.paymentMode,
    this.referenceNumber,
    this.notes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentMade.fromJson(Map<String, dynamic> json) {
    return PaymentMade(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      billId: json['bill_id'] as int? ?? json['billId'] as int? ?? 0,
      vendorId: json['vendor_id'] as int? ?? json['vendorId'] as int?,
      vendorName: json['vendor_name'] as String? ?? json['vendorName'] as String?,
      billNumber: json['bill_number'] as String? ?? json['billNumber'] as String?,
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      paymentMode: json['payment_mode'] as String? ?? json['paymentMode'] as String?,
      referenceNumber: json['reference_number'] as String? ?? json['referenceNumber'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'paid',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bill_id': billId,
      'vendor_id': vendorId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_mode': paymentMode,
      'reference_number': referenceNumber,
      'notes': notes,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
