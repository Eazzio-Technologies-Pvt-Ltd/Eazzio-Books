import 'package:mobile_books/features/credit_notes/data/models/credit_note_item.dart';

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
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      customerId: json['customer_id'] as int? ?? json['customerId'] as int?,
      invoiceId: json['invoice_id'] as int? ?? json['invoiceId'] as int?,
      creditNoteNumber: json['credit_note_number'] as String? ?? json['creditNoteNumber'] as String? ?? '',
      creditNoteDate: json['credit_note_date'] != null
          ? DateTime.tryParse(json['credit_note_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      referenceNumber: json['reference_number'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'Draft',
      subtotal: (json['subtotal'] as num? ?? 0.0).toDouble(),
      discountTotal: (json['discount_total'] as num? ?? 0.0).toDouble(),
      taxTotal: (json['tax_total'] as num? ?? 0.0).toDouble(),
      total: (json['total'] as num? ?? 0.0).toDouble(),
      appliedAmount: (json['applied_amount'] as num? ?? 0.0).toDouble(),
      remainingAmount: (json['remaining_amount'] as num? ?? 0.0).toDouble(),
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
