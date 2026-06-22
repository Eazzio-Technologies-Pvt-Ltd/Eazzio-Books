import 'package:mobile_books/features/dashboard/data/models/bank_account.dart';

class DashboardSummary {
  final TopSummary topSummary;
  final SelectedMonthSummary selectedMonth;
  final NextMonthSummary nextMonth;
  final DashboardDetails details;
  final DashboardChartData chartData;

  DashboardSummary({
    required this.topSummary,
    required this.selectedMonth,
    required this.nextMonth,
    required this.details,
    required this.chartData,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      topSummary: TopSummary.fromJson(json['top_summary'] as Map<String, dynamic>? ?? {}),
      selectedMonth: SelectedMonthSummary.fromJson(json['selected_month'] as Map<String, dynamic>? ?? {}),
      nextMonth: NextMonthSummary.fromJson(json['next_month'] as Map<String, dynamic>? ?? {}),
      details: DashboardDetails.fromJson(json['details'] as Map<String, dynamic>? ?? {}),
      chartData: DashboardChartData.fromJson(json['chartData'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class TopSummary {
  final double totalReceivables;
  final double totalPayables;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double cashBankBalance;

  TopSummary({
    required this.totalReceivables,
    required this.totalPayables,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.cashBankBalance,
  });

  factory TopSummary.fromJson(Map<String, dynamic> json) {
    return TopSummary(
      totalReceivables: (json['total_receivables'] as num?)?.toDouble() ?? 0.0,
      totalPayables: (json['total_payables'] as num?)?.toDouble() ?? 0.0,
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
      cashBankBalance: (json['cash_bank_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SelectedMonthSummary {
  final int month;
  final int year;
  final String label;
  final double incomeReceived;
  final double expenses;
  final double staffSalary;
  final double writeoff;
  final double projectedPayments;
  final double expectedPayables;
  final double profit;
  final double netCashPosition;

  SelectedMonthSummary({
    required this.month,
    required this.year,
    required this.label,
    required this.incomeReceived,
    required this.expenses,
    required this.staffSalary,
    required this.writeoff,
    required this.projectedPayments,
    required this.expectedPayables,
    required this.profit,
    required this.netCashPosition,
  });

  factory SelectedMonthSummary.fromJson(Map<String, dynamic> json) {
    return SelectedMonthSummary(
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? 2026,
      label: json['label'] as String? ?? '',
      incomeReceived: (json['income_received'] as num?)?.toDouble() ?? 0.0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
      staffSalary: (json['staff_salary'] as num?)?.toDouble() ?? 0.0,
      writeoff: (json['writeoff'] as num?)?.toDouble() ?? 0.0,
      projectedPayments: (json['projected_payments'] as num?)?.toDouble() ?? 0.0,
      expectedPayables: (json['expected_payables'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      netCashPosition: (json['net_cash_position'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NextMonthSummary {
  final int month;
  final int year;
  final String label;
  final double projectedIncome;
  final double projectedPayments;
  final double projectedExpenses;
  final double expectedPayables;
  final double staffSalary;
  final double writeoff;
  final double projectedProfit;

  NextMonthSummary({
    required this.month,
    required this.year,
    required this.label,
    required this.projectedIncome,
    required this.projectedPayments,
    required this.projectedExpenses,
    required this.expectedPayables,
    required this.staffSalary,
    required this.writeoff,
    required this.projectedProfit,
  });

  factory NextMonthSummary.fromJson(Map<String, dynamic> json) {
    return NextMonthSummary(
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? 2026,
      label: json['label'] as String? ?? '',
      projectedIncome: (json['projected_income'] as num?)?.toDouble() ?? 0.0,
      projectedPayments: (json['projected_payments'] as num?)?.toDouble() ?? 0.0,
      projectedExpenses: (json['projected_expenses'] as num?)?.toDouble() ?? 0.0,
      expectedPayables: (json['expected_payables'] as num?)?.toDouble() ?? 0.0,
      staffSalary: (json['staff_salary'] as num?)?.toDouble() ?? 0.0,
      writeoff: (json['writeoff'] as num?)?.toDouble() ?? 0.0,
      projectedProfit: (json['projected_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardDetails {
  final List<dynamic> receivables;
  final List<dynamic> paymentsReceived;
  final List<dynamic> expenses;
  final List<dynamic> payables;

  DashboardDetails({
    required this.receivables,
    required this.paymentsReceived,
    required this.expenses,
    required this.payables,
  });

  factory DashboardDetails.fromJson(Map<String, dynamic> json) {
    return DashboardDetails(
      receivables: json['receivables'] as List? ?? [],
      paymentsReceived: json['payments_received'] as List? ?? [],
      expenses: json['expenses'] as List? ?? [],
      payables: json['payables'] as List? ?? [],
    );
  }
}

class DashboardChartData {
  final List<CashFlowPoint> cashFlowYearly;
  final List<CashFlowPoint> incomeExpense6Months;
  final List<ExpenseCategoryPoint> topExpenses;
  final List<BankAccount> banks;

  DashboardChartData({
    required this.cashFlowYearly,
    required this.incomeExpense6Months,
    required this.topExpenses,
    required this.banks,
  });

  factory DashboardChartData.fromJson(Map<String, dynamic> json) {
    final cashFlowList = json['cashFlowYearly'] as List? ?? [];
    final ieList = json['incomeExpense6Months'] as List? ?? [];
    final topExpList = json['topExpenses'] as List? ?? [];
    final bankList = json['banks'] as List? ?? [];

    return DashboardChartData(
      cashFlowYearly: cashFlowList.map((e) => CashFlowPoint.fromJson(e as Map<String, dynamic>)).toList(),
      incomeExpense6Months: ieList.map((e) => CashFlowPoint.fromJson(e as Map<String, dynamic>)).toList(),
      topExpenses: topExpList.map((e) => ExpenseCategoryPoint.fromJson(e as Map<String, dynamic>)).toList(),
      banks: bankList.map((e) => BankAccount.fromJson(e as Map<String, dynamic>)).toList(),
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
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseCategoryPoint {
  final String name;
  final double value;

  ExpenseCategoryPoint({
    required this.name,
    required this.value,
  });

  factory ExpenseCategoryPoint.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryPoint(
      name: json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
