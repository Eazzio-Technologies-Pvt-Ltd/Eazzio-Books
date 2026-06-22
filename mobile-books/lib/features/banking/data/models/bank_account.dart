class BankAccount {
  final int id;
  final int userId;
  final String accountName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final double openingBalance;
  final double currentBalance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BankAccount({
    required this.id,
    required this.userId,
    required this.accountName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.openingBalance,
    required this.currentBalance,
    this.createdAt,
    this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      accountName: json['account_name'] as String? ?? json['accountName'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? json['bankName'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? json['accountNumber'] as String? ?? '',
      ifscCode: json['ifsc_code'] as String? ?? json['ifscCode'] as String? ?? '',
      openingBalance: (json['opening_balance'] as num? ?? json['openingBalance'] as num? ?? 0.0).toDouble(),
      currentBalance: (json['current_balance'] as num? ?? json['currentBalance'] as num? ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_name': accountName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  BankAccount copyWith({
    int? id,
    int? userId,
    String? accountName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    double? openingBalance,
    double? currentBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountName: accountName ?? this.accountName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
