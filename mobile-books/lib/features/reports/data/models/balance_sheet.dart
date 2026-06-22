class BalanceSheetAccount {
  final String accountCode;
  final String accountName;
  final String accountType;
  final double totalDebit;
  final double totalCredit;
  final double balance;

  BalanceSheetAccount({
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.totalDebit,
    required this.totalCredit,
    required this.balance,
  });

  factory BalanceSheetAccount.fromJson(Map<String, dynamic> json) {
    return BalanceSheetAccount(
      accountCode: json['account_code'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountType: json['account_type'] as String? ?? '',
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BalanceSheetSection {
  final List<BalanceSheetAccount> accounts;
  final double total;

  BalanceSheetSection({
    required this.accounts,
    required this.total,
  });

  factory BalanceSheetSection.fromJson(Map<String, dynamic> json) {
    final list = json['accounts'] as List? ?? [];
    return BalanceSheetSection(
      accounts: list.map((e) => BalanceSheetAccount.fromJson(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BalanceSheetReport {
  final BalanceSheetSection assets;
  final BalanceSheetSection liabilities;
  final BalanceSheetSection equity;

  BalanceSheetReport({
    required this.assets,
    required this.liabilities,
    required this.equity,
  });

  factory BalanceSheetReport.fromJson(Map<String, dynamic> json) {
    return BalanceSheetReport(
      assets: BalanceSheetSection.fromJson(json['assets'] as Map<String, dynamic>? ?? {}),
      liabilities: BalanceSheetSection.fromJson(json['liabilities'] as Map<String, dynamic>? ?? {}),
      equity: BalanceSheetSection.fromJson(json['equity'] as Map<String, dynamic>? ?? {}),
    );
  }
}
