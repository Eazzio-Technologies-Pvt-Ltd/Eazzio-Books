double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class CashFlowActivity {
  final String description;
  final double amount;

  CashFlowActivity({
    required this.description,
    required this.amount,
  });

  factory CashFlowActivity.fromJson(Map<String, dynamic> json) {
    return CashFlowActivity(
      description: json['description'] as String? ?? 'Uncategorized Transaction',
      amount: _parseDouble(json['amount']),
    );
  }
}

class CashFlowReport {
  final List<CashFlowActivity> operatingActivities;
  final double netCashFlow;

  CashFlowReport({
    required this.operatingActivities,
    required this.netCashFlow,
  });

  factory CashFlowReport.fromJson(Map<String, dynamic> json) {
    final list = json['operating_activities'] as List? ?? [];
    return CashFlowReport(
      operatingActivities: list.map((e) => CashFlowActivity.fromJson(e as Map<String, dynamic>)).toList(),
      netCashFlow: _parseDouble(json['net_cash_flow']),
    );
  }
}
