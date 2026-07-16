double _parseDbl(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int? _parseIntPS(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// Mirrors the `invoice_payment_schedules` table in the backend.
class PaymentSchedule {
  final int id;
  final int invoiceId;
  final int? organizationId;
  final int? customerId;
  final DateTime? dueDate;
  final double dueAmount;
  final double paidAmount;
  final double balanceAmount;
  /// 'pending' | 'partial' | 'paid' | 'overdue'
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentSchedule({
    required this.id,
    required this.invoiceId,
    this.organizationId,
    this.customerId,
    this.dueDate,
    required this.dueAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      id: _parseIntPS(json['id']) ?? 0,
      invoiceId: _parseIntPS(json['invoice_id']) ?? 0,
      organizationId: _parseIntPS(json['organization_id']),
      customerId: _parseIntPS(json['customer_id']),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      dueAmount: _parseDbl(json['due_amount']),
      paidAmount: _parseDbl(json['paid_amount']),
      balanceAmount: _parseDbl(json['balance_amount']),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'organization_id': organizationId,
      'customer_id': customerId,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'due_amount': dueAmount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status,
    };
  }

  /// Creates a new schedule entry for submission (no id/invoice_id yet).
  Map<String, dynamic> toCreateJson() {
    return {
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'due_amount': dueAmount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status,
    };
  }

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != 'paid';
  }

  @override
  String toString() =>
      'PaymentSchedule(id: $id, due: $dueAmount, balance: $balanceAmount, status: $status)';
}
