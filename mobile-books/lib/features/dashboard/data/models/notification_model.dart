class NotificationModel {
  final int id;
  final String type;
  final int invoiceId;
  final String invoiceNumber;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final DateTime dueDate;
  final double balanceAmount;

  NotificationModel({
    required this.id,
    required this.type,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.dueDate,
    required this.balanceAmount,
  });

  bool get isBill => type == 'bill_due' || type == 'projected_expense' || invoiceNumber.toLowerCase().contains('bill') || (customerName.isNotEmpty && !type.contains('invoice'));

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    // Map either bill or invoice fields
    final resolvedId = parseInt(json['id'] ?? json['bill_id'] ?? json['invoice_id']);
    final resolvedType = json['type'] as String? ?? 'installment_due';
    final resolvedInvoiceId = parseInt(json['bill_id'] ?? json['invoice_id']);
    final resolvedNumber = (json['bill_number'] ?? json['invoice_number'] ?? '') as String;
    final resolvedName = (json['vendor_name'] ?? json['customer_name'] ?? '') as String;
    final resolvedEmail = (json['customer_email'] ?? '') as String;
    final resolvedPhone = (json['customer_phone'] ?? json['customer_mobile'] ?? '') as String;
    final resolvedAmount = parseDouble(json['pending_amount'] ?? json['balance_amount']);

    return NotificationModel(
      id: resolvedId,
      type: resolvedType,
      invoiceId: resolvedInvoiceId,
      invoiceNumber: resolvedNumber,
      customerName: resolvedName,
      customerEmail: resolvedEmail,
      customerPhone: resolvedPhone,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String) 
          : DateTime.now(),
      balanceAmount: resolvedAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'invoice_id': invoiceId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'due_date': dueDate.toIso8601String(),
      'balance_amount': balanceAmount,
    };
  }
}
