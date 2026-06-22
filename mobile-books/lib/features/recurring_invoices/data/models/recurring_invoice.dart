import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice_item.dart';

class RecurringInvoice {
  final int id;
  final int userId;
  final String recurringInvoiceNumber;
  final String profileName;
  final int customerId;
  final String frequency; // 'Weekly', 'Monthly', 'Quarterly', 'Yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextInvoiceDate;
  final DateTime? lastInvoiceDate;
  final String status; // 'Active', 'Paused', 'Stopped'
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final String? notes;
  final String? termsConditions;
  final bool autoSendEmail;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<RecurringInvoiceItem>? items;
  final String? customerName; // helper for listings

  RecurringInvoice({
    required this.id,
    required this.userId,
    required this.recurringInvoiceNumber,
    required this.profileName,
    required this.customerId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.nextInvoiceDate,
    this.lastInvoiceDate,
    required this.status,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    this.notes,
    this.termsConditions,
    required this.autoSendEmail,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.items,
    this.customerName,
  });

  factory RecurringInvoice.fromJson(Map<String, dynamic> json) {
    return RecurringInvoice(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      recurringInvoiceNumber: json['recurring_invoice_number'] as String? ?? json['recurringInvoiceNumber'] as String? ?? '',
      profileName: json['profile_name'] as String? ?? json['profileName'] as String? ?? '',
      customerId: json['customer_id'] as int? ?? json['customerId'] as int? ?? 0,
      frequency: json['frequency'] as String? ?? 'Monthly',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      nextInvoiceDate: json['next_invoice_date'] != null ? DateTime.tryParse(json['next_invoice_date'] as String) : null,
      lastInvoiceDate: json['last_invoice_date'] != null ? DateTime.tryParse(json['last_invoice_date'] as String) : null,
      status: json['status'] as String? ?? 'Active',
      subtotal: (json['subtotal'] as num? ?? 0.0).toDouble(),
      discountTotal: (json['discount_total'] as num? ?? 0.0).toDouble(),
      taxTotal: (json['tax_total'] as num? ?? 0.0).toDouble(),
      total: (json['total'] as num? ?? 0.0).toDouble(),
      notes: json['notes'] as String?,
      termsConditions: json['terms_conditions'] as String? ?? json['termsConditions'] as String?,
      autoSendEmail: json['auto_send_email'] as bool? ?? false,
      createdBy: json['created_by'] as int? ?? json['createdBy'] as int?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => RecurringInvoiceItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      customerName: json['customer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recurring_invoice_number': recurringInvoiceNumber,
      'profile_name': profileName,
      'customer_id': customerId,
      'frequency': frequency,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'next_invoice_date': nextInvoiceDate?.toIso8601String().split('T')[0],
      'last_invoice_date': lastInvoiceDate?.toIso8601String().split('T')[0],
      'status': status,
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'tax_total': taxTotal,
      'total': total,
      'notes': notes,
      'terms_conditions': termsConditions,
      'auto_send_email': autoSendEmail,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (items != null) 'items': items!.map((i) => i.toJson()).toList(),
    };
  }
}
