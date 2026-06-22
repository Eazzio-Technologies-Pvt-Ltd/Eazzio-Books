class ChartOfAccount {
  final int id;
  final int userId;
  final String accountName;
  final String? accountCode;
  final String accountType; // e.g. Asset, Liability, Equity, Income, Expense
  final int? parentAccountId;
  final double openingBalance;
  final double currentBalance;
  final String? description;
  final String status; // 'active', 'inactive'
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChartOfAccount({
    required this.id,
    required this.userId,
    required this.accountName,
    this.accountCode,
    required this.accountType,
    this.parentAccountId,
    required this.openingBalance,
    required this.currentBalance,
    this.description,
    required this.status,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory ChartOfAccount.fromJson(Map<String, dynamic> json) {
    return ChartOfAccount(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      accountName: json['account_name'] as String? ?? json['accountName'] as String? ?? '',
      accountCode: json['account_code'] as String? ?? json['accountCode'] as String?,
      accountType: json['account_type'] as String? ?? json['accountType'] as String? ?? 'Asset',
      parentAccountId: json['parent_account_id'] as int? ?? json['parentAccountId'] as int?,
      openingBalance: (json['opening_balance'] as num? ?? json['openingBalance'] as num? ?? 0.0).toDouble(),
      currentBalance: (json['current_balance'] as num? ?? json['currentBalance'] as num? ?? 0.0).toDouble(),
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      isDeleted: json['is_deleted'] as bool? ?? json['isDeleted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_name': accountName,
      'account_code': accountCode,
      'account_type': accountType,
      'parent_account_id': parentAccountId,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'description': description,
      'status': status,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ChartOfAccount copyWith({
    int? id,
    int? userId,
    String? accountName,
    String? accountCode,
    String? accountType,
    int? parentAccountId,
    double? openingBalance,
    double? currentBalance,
    String? description,
    String? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChartOfAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountName: accountName ?? this.accountName,
      accountCode: accountCode ?? this.accountCode,
      accountType: accountType ?? this.accountType,
      parentAccountId: parentAccountId ?? this.parentAccountId,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      description: description ?? this.description,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
