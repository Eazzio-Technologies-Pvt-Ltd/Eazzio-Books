class JournalLine {
  final int id;
  final int journalEntryId;
  final int accountId;
  final String? description;
  final double debit;
  final double credit;
  final DateTime? createdAt;

  // Joined properties from ChartOfAccounts
  final String? accountName;
  final String? accountCode;

  JournalLine({
    required this.id,
    required this.journalEntryId,
    required this.accountId,
    this.description,
    required this.debit,
    required this.credit,
    this.createdAt,
    this.accountName,
    this.accountCode,
  });

  factory JournalLine.fromJson(Map<String, dynamic> json) {
    return JournalLine(
      id: json['id'] as int? ?? 0,
      journalEntryId: json['journal_entry_id'] as int? ?? json['journalEntryId'] as int? ?? 0,
      accountId: json['account_id'] as int? ?? json['accountId'] as int? ?? 0,
      description: json['description'] as String?,
      debit: (json['debit'] as num? ?? 0.0).toDouble(),
      credit: (json['credit'] as num? ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      accountName: json['account_name'] as String? ?? json['accountName'] as String?,
      accountCode: json['account_code'] as String? ?? json['accountCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'journal_entry_id': journalEntryId,
      'account_id': accountId,
      'description': description,
      'debit': debit,
      'credit': credit,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  JournalLine copyWith({
    int? id,
    int? journalEntryId,
    int? accountId,
    String? description,
    double? debit,
    double? credit,
    DateTime? createdAt,
    String? accountName,
    String? accountCode,
  }) {
    return JournalLine(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      createdAt: createdAt ?? this.createdAt,
      accountName: accountName ?? this.accountName,
      accountCode: accountCode ?? this.accountCode,
    );
  }
}
