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

double _d(dynamic v) => v != null ? double.tryParse(v.toString()) ?? 0.0 : 0.0;

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
      totalReceivables: _d(json['total_receivables']),
      totalPayables: _d(json['total_payables']),
      totalIncome: _d(json['total_income']),
      totalExpenses: _d(json['total_expenses']),
      netProfit: _d(json['net_profit']),
      cashBankBalance: _d(json['cash_bank_balance']),
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
      incomeReceived: _d(json['income_received']),
      expenses: _d(json['expenses']),
      staffSalary: _d(json['staff_salary']),
      writeoff: _d(json['writeoff']),
      projectedPayments: _d(json['projected_payments']),
      expectedPayables: _d(json['expected_payables']),
      profit: _d(json['profit']),
      netCashPosition: _d(json['net_cash_position']),
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
      projectedIncome: _d(json['projected_income']),
      projectedPayments: _d(json['projected_payments']),
      projectedExpenses: _d(json['projected_expenses']),
      expectedPayables: _d(json['expected_payables']),
      staffSalary: _d(json['staff_salary']),
      writeoff: _d(json['writeoff']),
      projectedProfit: _d(json['projected_profit']),
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
      income: _d(json['income']),
      expense: _d(json['expense']),
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
      value: _d(json['value']),
    );
  }
}
