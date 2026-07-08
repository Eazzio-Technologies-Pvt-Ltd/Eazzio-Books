int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

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
      id: _parseInt(json['customer_id']) ?? _parseInt(json['vendor_id']) ?? 0,
      name: json['customer_name'] as String? ?? json['vendor_name'] as String? ?? '',
      current: _parseDouble(json['current']),
      days1To30: _parseDouble(json['days_1_30']),
      days31To60: _parseDouble(json['days_31_60']),
      days61To90: _parseDouble(json['days_61_90']),
      days90Plus: _parseDouble(json['days_90_plus']),
      totalDue: _parseDouble(json['total_due']),
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
