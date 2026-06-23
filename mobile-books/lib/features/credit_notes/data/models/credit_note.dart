import 'package:mobile_books/features/credit_notes/data/models/credit_note_item.dart';

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
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

class CreditNote {
  final int id;
  final int userId;
  final int? customerId;
  final int? invoiceId;
  final String creditNoteNumber;
  final DateTime creditNoteDate;
  final String? referenceNumber;
  final String? reason;
  final String status; // 'Draft', 'Open', 'Applied', 'Cancelled'
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final double? adjustment;
  final double appliedAmount;
  final double remainingAmount;
  final String? notes;
  final String? termsConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CreditNoteItem>? items;

  CreditNote({
    required this.id,
    required this.userId,
    this.customerId,
    this.invoiceId,
    required this.creditNoteNumber,
    required this.creditNoteDate,
    this.referenceNumber,
    this.reason,
    required this.status,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    this.adjustment,
    required this.appliedAmount,
    required this.remainingAmount,
    this.notes,
    this.termsConditions,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory CreditNote.fromJson(Map<String, dynamic> json) {
    return CreditNote(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? _parseInt(json['userId']) ?? 0,
      customerId: _parseInt(json['customer_id']) ?? _parseInt(json['customerId']),
      invoiceId: _parseInt(json['invoice_id']) ?? _parseInt(json['invoiceId']),
      creditNoteNumber: json['credit_note_number'] as String? ?? json['creditNoteNumber'] as String? ?? '',
      creditNoteDate: json['credit_note_date'] != null
          ? DateTime.tryParse(json['credit_note_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      referenceNumber: json['reference_number'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'Draft',
      subtotal: _parseDouble(json['subtotal']),
      discountTotal: _parseDouble(json['discount_total']),
      taxTotal: _parseDouble(json['tax_total']),
      total: _parseDouble(json['total']),
      adjustment: json['adjustment'] != null ? _parseDouble(json['adjustment']) : null,
      appliedAmount: _parseDouble(json['applied_amount']),
      remainingAmount: _parseDouble(json['remaining_amount']),
      notes: json['notes'] as String?,
      termsConditions: json['terms_conditions'] as String? ?? json['termsConditions'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => CreditNoteItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'invoice_id': invoiceId,
      'credit_note_number': creditNoteNumber,
      'credit_note_date': creditNoteDate.toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
      'reason': reason,
      'status': status,
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'tax_total': taxTotal,
      'total': total,
      'adjustment': adjustment,
      'applied_amount': appliedAmount,
      'remaining_amount': remainingAmount,
      'notes': notes,
      'terms_conditions': termsConditions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (items != null) 'items': items!.map((i) => i.toJson()).toList(),
    };
  }
}
