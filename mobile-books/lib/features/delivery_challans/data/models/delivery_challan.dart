import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan_item.dart';

class DeliveryChallan {
  final int id;
  final int userId;
  final int? customerId;
  final int? salesOrderId;
  final String deliveryChallanNumber;
  final DateTime challanDate;
  final DateTime? deliveryDate;
  final String? deliveryAddress;
  final String? referenceNumber;
  final String status; // 'Draft', 'Delivered', 'Cancelled'
  final bool stockReduced;
  final String? notes;
  final String? termsConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DeliveryChallanItem>? items;

  DeliveryChallan({
    required this.id,
    required this.userId,
    this.customerId,
    this.salesOrderId,
    required this.deliveryChallanNumber,
    required this.challanDate,
    this.deliveryDate,
    this.deliveryAddress,
    this.referenceNumber,
    required this.status,
    required this.stockReduced,
    this.notes,
    this.termsConditions,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory DeliveryChallan.fromJson(Map<String, dynamic> json) {
    return DeliveryChallan(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      customerId: json['customer_id'] as int? ?? json['customerId'] as int?,
      salesOrderId: json['sales_order_id'] as int? ?? json['salesOrderId'] as int?,
      deliveryChallanNumber: json['delivery_challan_number'] as String? ?? json['deliveryChallanNumber'] as String? ?? '',
      challanDate: json['challan_date'] != null
          ? DateTime.tryParse(json['challan_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'] as String)
          : null,
      deliveryAddress: json['delivery_address'] as String? ?? json['deliveryAddress'] as String?,
      referenceNumber: json['reference_number'] as String?,
      status: json['status'] as String? ?? 'Draft',
      stockReduced: json['stock_reduced'] as bool? ?? false,
      notes: json['notes'] as String?,
      termsConditions: json['terms_conditions'] as String? ?? json['termsConditions'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => DeliveryChallanItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'sales_order_id': salesOrderId,
      'delivery_challan_number': deliveryChallanNumber,
      'challan_date': challanDate.toIso8601String().split('T')[0],
      'delivery_date': deliveryDate?.toIso8601String().split('T')[0],
      'delivery_address': deliveryAddress,
      'reference_number': referenceNumber,
      'status': status,
      'stock_reduced': stockReduced,
      'notes': notes,
      'terms_conditions': termsConditions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (items != null) 'items': items!.map((i) => i.toJson()).toList(),
    };
  }
}
