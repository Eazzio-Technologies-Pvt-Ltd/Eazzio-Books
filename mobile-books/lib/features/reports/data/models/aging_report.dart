class AgingEntry {
  final int id;
  final String name;
  final double current;
  final double days1To30;
  final double days31To60;
  final double days61To90;
  final double days90Plus;
  final double totalDue;

  AgingEntry({
    required this.id,
    required this.name,
    required this.current,
    required this.days1To30,
    required this.days31To60,
    required this.days61To90,
    required this.days90Plus,
    required this.totalDue,
  });

  factory AgingEntry.fromJson(Map<String, dynamic> json) {
    return AgingEntry(
      id: json['customer_id'] as int? ?? json['vendor_id'] as int? ?? 0,
      name: json['customer_name'] as String? ?? json['vendor_name'] as String? ?? '',
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      days1To30: (json['days_1_30'] as num?)?.toDouble() ?? 0.0,
      days31To60: (json['days_31_60'] as num?)?.toDouble() ?? 0.0,
      days61To90: (json['days_61_90'] as num?)?.toDouble() ?? 0.0,
      days90Plus: (json['days_90_plus'] as num?)?.toDouble() ?? 0.0,
      totalDue: (json['total_due'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AgingReport {
  final List<AgingEntry> entries;

  AgingReport({required this.entries});

  factory AgingReport.fromCustomerJson(Map<String, dynamic> json) {
    final list = json['customer_aging'] as List? ?? [];
    return AgingReport(
      entries: list.map((e) => AgingEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  factory AgingReport.fromVendorJson(Map<String, dynamic> json) {
    final list = json['vendor_aging'] as List? ?? [];
    return AgingReport(
      entries: list.map((e) => AgingEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
