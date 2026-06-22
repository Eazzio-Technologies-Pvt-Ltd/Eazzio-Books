class DashboardModel {
  final double totalReceivables;
  final double totalPayables;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final List<BankDetails> banks;
  final List<CashFlowPoint> cashFlowYearly;

  DashboardModel({
    required this.totalReceivables,
    required this.totalPayables,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.banks,
    required this.cashFlowYearly,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final topSummary = json['top_summary'] as Map<String, dynamic>? ?? {};
    final chartData = json['chartData'] as Map<String, dynamic>? ?? {};
    
    final List<dynamic> banksJson = chartData['banks'] as List<dynamic>? ?? [];
    final List<dynamic> cashFlowJson = chartData['cashFlowYearly'] as List<dynamic>? ?? [];

    return DashboardModel(
      totalReceivables: (topSummary['total_receivables'] as num? ?? 0.0).toDouble(),
      totalPayables: (topSummary['total_payables'] as num? ?? 0.0).toDouble(),
      totalIncome: (topSummary['total_income'] as num? ?? 0.0).toDouble(),
      totalExpenses: (topSummary['total_expenses'] as num? ?? 0.0).toDouble(),
      netProfit: (topSummary['net_profit'] as num? ?? 0.0).toDouble(),
      banks: banksJson.map((b) => BankDetails.fromJson(b)).toList(),
      cashFlowYearly: cashFlowJson.map((c) => CashFlowPoint.fromJson(c)).toList(),
    );
  }
}

class BankDetails {
  final String name;
  final String accountNumber;
  final double balance;

  BankDetails({
    required this.name,
    required this.accountNumber,
    required this.balance,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      name: json['name'] as String? ?? 'Unnamed Bank',
      accountNumber: json['account_number'] as String? ?? '—',
      balance: (json['balance'] as num? ?? 0.0).toDouble(),
    );
  }
}

class CashFlowPoint {
  final String name;
  final double income;
  final double expense;

  CashFlowPoint({
    required this.name,
    required this.income,
    required this.expense,
  });

  factory CashFlowPoint.fromJson(Map<String, dynamic> json) {
    return CashFlowPoint(
      name: json['name'] as String? ?? '',
      income: (json['income'] as num? ?? 0.0).toDouble(),
      expense: (json['expense'] as num? ?? 0.0).toDouble(),
    );
  }
}
