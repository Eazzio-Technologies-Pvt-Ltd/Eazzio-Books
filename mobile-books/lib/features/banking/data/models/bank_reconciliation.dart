class BankReconciliation {
  final int id;
  final int userId;
  final int bankAccountId;
  final DateTime? statementStartDate;
  final DateTime? statementEndDate;
  final double openingBalance;
  final double closingBalance;
  final double totalDeposits;
  final double totalWithdrawals;
  final double difference;
  final String status; // 'draft' or 'reconciled'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BankReconciliation({
    required this.id,
    required this.userId,
    required this.bankAccountId,
    this.statementStartDate,
    this.statementEndDate,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.difference,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BankReconciliation.fromJson(Map<String, dynamic> json) {
    return BankReconciliation(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      bankAccountId: json['bank_account_id'] as int? ?? json['bankAccountId'] as int? ?? 0,
      statementStartDate: json['statement_start_date'] != null ? DateTime.tryParse(json['statement_start_date'] as String) : null,
      statementEndDate: json['statement_end_date'] != null ? DateTime.tryParse(json['statement_end_date'] as String) : null,
      openingBalance: (json['opening_balance'] as num? ?? json['openingBalance'] as num? ?? 0.0).toDouble(),
      closingBalance: (json['closing_balance'] as num? ?? json['closingBalance'] as num? ?? 0.0).toDouble(),
      totalDeposits: (json['total_deposits'] as num? ?? json['totalDeposits'] as num? ?? 0.0).toDouble(),
      totalWithdrawals: (json['total_withdrawals'] as num? ?? json['totalWithdrawals'] as num? ?? 0.0).toDouble(),
      difference: (json['difference'] as num? ?? json['difference'] as num? ?? 0.0).toDouble(),
      status: json['status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_account_id': bankAccountId,
      'statement_start_date': statementStartDate?.toIso8601String().split('T')[0],
      'statement_end_date': statementEndDate?.toIso8601String().split('T')[0],
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'total_deposits': totalDeposits,
      'total_withdrawals': totalWithdrawals,
      'difference': difference,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  BankReconciliation copyWith({
    int? id,
    int? userId,
    int? bankAccountId,
    DateTime? statementStartDate,
    DateTime? statementEndDate,
    double? openingBalance,
    double? closingBalance,
    double? totalDeposits,
    double? totalWithdrawals,
    double? difference,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankReconciliation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      statementStartDate: statementStartDate ?? this.statementStartDate,
      statementEndDate: statementEndDate ?? this.statementEndDate,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      difference: difference ?? this.difference,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
