class PnlAccount {
  final String accountCode;
  final String accountName;
  final String accountType;
  final double totalDebit;
  final double totalCredit;
  final double balance;

  PnlAccount({
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.totalDebit,
    required this.totalCredit,
    required this.balance,
  });

  factory PnlAccount.fromJson(Map<String, dynamic> json) {
    return PnlAccount(
      accountCode: json['account_code'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountType: json['account_type'] as String? ?? '',
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PnlSection {
  final List<PnlAccount> accounts;
  final double total;

  PnlSection({
    required this.accounts,
    required this.total,
  });

  factory PnlSection.fromJson(Map<String, dynamic> json) {
    final list = json['accounts'] as List? ?? [];
    return PnlSection(
      accounts: list.map((e) => PnlAccount.fromJson(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProfitAndLossReport {
  final PnlSection income;
  final PnlSection expense;
  final double netProfit;

  ProfitAndLossReport({
    required this.income,
    required this.expense,
    required this.netProfit,
  });

  factory ProfitAndLossReport.fromJson(Map<String, dynamic> json) {
    return ProfitAndLossReport(
      income: PnlSection.fromJson(json['income'] as Map<String, dynamic>? ?? {}),
      expense: PnlSection.fromJson(json['expense'] as Map<String, dynamic>? ?? {}),
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
