import 'package:mobile_books/features/purchase_orders/data/models/purchase_order_item.dart';

class PurchaseOrder {
  final int id;
  final int userId;
  final int? vendorId;
  final String purchaseOrderNumber;
  final DateTime purchaseOrderDate;
  final DateTime? expectedDeliveryDate;
  final String? referenceNumber;
  final String status; // 'Draft', 'Open', 'Closed', 'Cancelled'
  final String? notes;
  final String? termsConditions;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PurchaseOrderItem>? items;

  PurchaseOrder({
    required this.id,
    required this.userId,
    this.vendorId,
    required this.purchaseOrderNumber,
    required this.purchaseOrderDate,
    this.expectedDeliveryDate,
    this.referenceNumber,
    required this.status,
    this.notes,
    this.termsConditions,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.totalAmount,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      vendorId: json['vendor_id'] as int? ?? json['vendorId'] as int?,
      purchaseOrderNumber: json['purchase_order_number'] as String? ?? json['purchaseOrderNumber'] as String? ?? '',
      purchaseOrderDate: json['purchase_order_date'] != null
          ? DateTime.tryParse(json['purchase_order_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.tryParse(json['expected_delivery_date'] as String)
          : null,
      referenceNumber: json['reference_number'] as String?,
      status: json['status'] as String? ?? 'Draft',
      notes: json['notes'] as String?,
      termsConditions: json['terms_conditions'] as String? ?? json['termsConditions'] as String?,
      subtotal: json['subtotal'] != null ? double.tryParse(json['subtotal'].toString()) ?? 0.0 : 0.0,
      discountTotal: json['discount_total'] != null ? double.tryParse(json['discount_total'].toString()) ?? 0.0 : 0.0,
      taxTotal: json['tax_total'] != null ? double.tryParse(json['tax_total'].toString()) ?? 0.0 : 0.0,
      totalAmount: json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) ?? 0.0 : 0.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vendor_id': vendorId,
      'purchase_order_number': purchaseOrderNumber,
      'purchase_order_date': purchaseOrderDate.toIso8601String().split('T')[0],
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
      'status': status,
      'notes': notes,
      'terms_conditions': termsConditions,
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'tax_total': taxTotal,
      'total_amount': totalAmount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
    };
  }
}
