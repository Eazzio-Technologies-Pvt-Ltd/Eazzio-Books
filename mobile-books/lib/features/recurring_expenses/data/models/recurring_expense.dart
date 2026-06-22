class RecurringExpense {
  final int id;
  final String expenseName;
  final String category;
  final double amount;
  final String frequency; // 'Monthly', 'Quarterly', 'Yearly'
  final int dueDay; // 1-31
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'Active', 'Paused', 'Stopped'
  final String? notes;
  final int createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RecurringExpense({
    required this.id,
    required this.expenseName,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.dueDay,
    required this.startDate,
    this.endDate,
    required this.status,
    this.notes,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] as int,
      expenseName: json['expense_name'] as String? ?? json['expenseName'] as String? ?? '',
      category: json['category'] as String? ?? 'General Expense',
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      frequency: json['frequency'] as String? ?? 'Monthly',
      dueDay: json['due_day'] as int? ?? json['dueDay'] as int? ?? 1,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? 'Active',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as int? ?? json['createdBy'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_name': expenseName,
      'category': category,
      'amount': amount,
      'frequency': frequency,
      'due_day': dueDay,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'status': status,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}
