import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit_item.dart';

class VendorCredit {
  final int id;
  final int userId;
  final int? vendorId;
  final int? billId;
  final String vendorCreditNumber;
  final DateTime vendorCreditDate;
  final String? referenceNumber;
  final String? reason;
  final String status; // 'Draft', 'Open', 'Closed'
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
  final List<VendorCreditItem>? items;

  VendorCredit({
    required this.id,
    required this.userId,
    this.vendorId,
    this.billId,
    required this.vendorCreditNumber,
    required this.vendorCreditDate,
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

  factory VendorCredit.fromJson(Map<String, dynamic> json) {
    return VendorCredit(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      vendorId: json['vendor_id'] as int? ?? json['vendorId'] as int?,
      billId: json['bill_id'] as int? ?? json['billId'] as int?,
      vendorCreditNumber: json['vendor_credit_number'] as String? ?? json['vendorCreditNumber'] as String? ?? '',
      vendorCreditDate: json['vendor_credit_date'] != null
          ? DateTime.tryParse(json['vendor_credit_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      referenceNumber: json['reference_number'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'Draft',
      subtotal: json['subtotal'] != null ? double.tryParse(json['subtotal'].toString()) ?? 0.0 : 0.0,
      discountTotal: json['discount_total'] != null ? double.tryParse(json['discount_total'].toString()) ?? 0.0 : 0.0,
      taxTotal: json['tax_total'] != null ? double.tryParse(json['tax_total'].toString()) ?? 0.0 : 0.0,
      total: json['total'] != null ? double.tryParse(json['total'].toString()) ?? 0.0 : 0.0,
      appliedAmount: json['applied_amount'] != null ? double.tryParse(json['applied_amount'].toString()) ?? 0.0 : 0.0,
      remainingAmount: json['remaining_amount'] != null ? double.tryParse(json['remaining_amount'].toString()) ?? 0.0 : 0.0,
      notes: json['notes'] as String?,
      termsConditions: json['terms_conditions'] as String? ?? json['termsConditions'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => VendorCreditItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vendor_id': vendorId,
      'bill_id': billId,
      'vendor_credit_number': vendorCreditNumber,
      'vendor_credit_date': vendorCreditDate.toIso8601String().split('T')[0],
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
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
    };
  }
}
