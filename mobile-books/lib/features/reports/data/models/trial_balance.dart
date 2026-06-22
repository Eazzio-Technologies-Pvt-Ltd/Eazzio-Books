class TrialBalanceAccount {
  final String accountCode;
  final String accountName;
  final String accountType;
  final double totalDebit;
  final double totalCredit;

  TrialBalanceAccount({
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.totalDebit,
    required this.totalCredit,
  });

  factory TrialBalanceAccount.fromJson(Map<String, dynamic> json) {
    return TrialBalanceAccount(
      accountCode: json['account_code'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountType: json['account_type'] as String? ?? '',
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_code': accountCode,
      'account_name': accountName,
      'account_type': accountType,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
    };
  }
}

class TrialBalanceReport {
  final List<TrialBalanceAccount> accounts;

  TrialBalanceReport({required this.accounts});

  factory TrialBalanceReport.fromJson(Map<String, dynamic> json) {
    final list = json['accounts'] as List? ?? [];
    return TrialBalanceReport(
      accounts: list.map((e) => TrialBalanceAccount.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
