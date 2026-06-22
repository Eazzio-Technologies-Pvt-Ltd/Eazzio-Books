import 'package:mobile_books/features/bills/data/models/bill_item.dart';

class Bill {
  final int id;
  final int userId;
  final int vendorId;
  final String billNumber;
  final DateTime billDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double adjustment;
  final double totalAmount;
  final double balanceDue;
  final String status; // 'draft', 'open', 'paid', 'partially_paid', 'void'
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<BillItem>? items;

  Bill({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.billNumber,
    required this.billDate,
    this.dueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.adjustment,
    required this.totalAmount,
    required this.balanceDue,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      vendorId: json['vendor_id'] as int? ?? json['vendorId'] as int? ?? 0,
      billNumber: json['bill_number'] as String? ?? json['billNumber'] as String? ?? '',
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      subtotal: json['subtotal'] != null ? double.tryParse(json['subtotal'].toString()) ?? 0.0 : 0.0,
      discountAmount: json['discount_amount'] != null ? double.tryParse(json['discount_amount'].toString()) ?? 0.0 : 0.0,
      taxAmount: json['tax_amount'] != null ? double.tryParse(json['tax_amount'].toString()) ?? 0.0 : 0.0,
      adjustment: json['adjustment'] != null ? double.tryParse(json['adjustment'].toString()) ?? 0.0 : 0.0,
      totalAmount: json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) ?? 0.0 : 0.0,
      balanceDue: json['balance_due'] != null ? double.tryParse(json['balance_due'].toString()) ?? 0.0 : 0.0,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vendor_id': vendorId,
      'bill_number': billNumber,
      'bill_date': billDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'adjustment': adjustment,
      'total_amount': totalAmount,
      'balance_due': balanceDue,
      'status': status,
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
    };
  }
}
