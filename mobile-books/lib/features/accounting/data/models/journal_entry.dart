import 'package:mobile_books/features/accounting/data/models/journal_line.dart';

class JournalEntry {
  final int id;
  final int userId;
  final String journalNumber;
  final DateTime journalDate;
  final String? referenceNumber;
  final String? notes;
  final double totalDebit;
  final double totalCredit;
  final String status; // e.g. 'published', 'draft'
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<JournalLine>? lines;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.journalNumber,
    required this.journalDate,
    this.referenceNumber,
    this.notes,
    required this.totalDebit,
    required this.totalCredit,
    required this.status,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.lines,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json, [List<dynamic>? linesJson]) {
    return JournalEntry(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      journalNumber: json['journal_number'] as String? ?? json['journalNumber'] as String? ?? '',
      journalDate: json['journal_date'] != null
          ? DateTime.parse(json['journal_date'] as String)
          : DateTime.now(),
      referenceNumber: json['reference_number'] as String? ?? json['referenceNumber'] as String?,
      notes: json['notes'] as String?,
      totalDebit: (json['total_debit'] as num? ?? json['totalDebit'] as num? ?? 0.0).toDouble(),
      totalCredit: (json['total_credit'] as num? ?? json['totalCredit'] as num? ?? 0.0).toDouble(),
      status: json['status'] as String? ?? 'published',
      isDeleted: json['is_deleted'] as bool? ?? json['isDeleted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      lines: linesJson?.map((e) => JournalLine.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'journal_number': journalNumber,
      'journal_date': journalDate.toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
      'notes': notes,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'status': status,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (lines != null) 'lines': lines!.map((e) => e.toJson()).toList(),
    };
  }

  JournalEntry copyWith({
    int? id,
    int? userId,
    String? journalNumber,
    DateTime? journalDate,
    String? referenceNumber,
    String? notes,
    double? totalDebit,
    double? totalCredit,
    String? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<JournalLine>? lines,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      journalNumber: journalNumber ?? this.journalNumber,
      journalDate: journalDate ?? this.journalDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lines: lines ?? this.lines,
    );
  }
}
