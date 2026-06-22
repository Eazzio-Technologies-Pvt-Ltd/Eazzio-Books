class Expense {
  final int id;
  final int userId;
  final int? vendorId;
  final String? vendorName;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? description;
  final String? reference;
  final String? attachmentUrl;
  final String status; // 'unpaid', 'paid'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Expense({
    required this.id,
    required this.userId,
    this.vendorId,
    this.vendorName,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.description,
    this.reference,
    this.attachmentUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      vendorId: json['vendor_id'] as int? ?? json['vendorId'] as int?,
      vendorName: json['vendor_name'] as String? ?? json['vendorName'] as String?,
      category: json['category'] as String? ?? 'Other Expenses',
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      expenseDate: json['expense_date'] != null
          ? DateTime.tryParse(json['expense_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      attachmentUrl: json['attachment_url'] as String? ?? json['attachmentUrl'] as String?,
      status: json['status'] as String? ?? 'unpaid',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vendor_id': vendorId,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'description': description,
      'reference': reference,
      'attachment_url': attachmentUrl,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
