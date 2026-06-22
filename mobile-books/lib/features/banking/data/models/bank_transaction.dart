class BankTransaction {
  final int id;
  final int bankAccountId;
  final int userId;
  final DateTime transactionDate;
  final String? description;
  final String transactionType; // 'deposit' or 'withdrawal'
  final double amount;
  final String? reference;
  final bool isReconciled;
  final DateTime? reconciledAt;
  final String? referenceNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BankTransaction({
    required this.id,
    required this.bankAccountId,
    required this.userId,
    required this.transactionDate,
    this.description,
    required this.transactionType,
    required this.amount,
    this.reference,
    required this.isReconciled,
    this.reconciledAt,
    this.referenceNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['id'] as int,
      bankAccountId: json['bank_account_id'] as int? ?? json['bankAccountId'] as int? ?? 0,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : DateTime.now(),
      description: json['description'] as String?,
      transactionType: json['transaction_type'] as String? ?? json['transactionType'] as String? ?? 'deposit',
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      reference: json['reference'] as String?,
      isReconciled: json['is_reconciled'] as bool? ?? json['isReconciled'] as bool? ?? false,
      reconciledAt: json['reconciled_at'] != null ? DateTime.tryParse(json['reconciled_at'] as String) : null,
      referenceNumber: json['reference_number'] as String? ?? json['referenceNumber'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_account_id': bankAccountId,
      'user_id': userId,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'description': description,
      'transaction_type': transactionType,
      'amount': amount,
      'reference': reference,
      'is_reconciled': isReconciled,
      'reconciled_at': reconciledAt?.toIso8601String(),
      'reference_number': referenceNumber,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  BankTransaction copyWith({
    int? id,
    int? bankAccountId,
    int? userId,
    DateTime? transactionDate,
    String? description,
    String? transactionType,
    double? amount,
    String? reference,
    bool? isReconciled,
    DateTime? reconciledAt,
    String? referenceNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankTransaction(
      id: id ?? this.id,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      userId: userId ?? this.userId,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
      isReconciled: isReconciled ?? this.isReconciled,
      reconciledAt: reconciledAt ?? this.reconciledAt,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
