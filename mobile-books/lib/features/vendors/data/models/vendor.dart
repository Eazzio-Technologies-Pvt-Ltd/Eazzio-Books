class Vendor {
  final int id;
  final int userId;
  final String displayName;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? gstin;
  final String? pan;
  final String? billingAddress;
  final String? shippingAddress;
  final double openingBalance;
  final String? paymentTerms;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vendor({
    required this.id,
    required this.userId,
    required this.displayName,
    this.companyName,
    this.email,
    this.phone,
    this.gstin,
    this.pan,
    this.billingAddress,
    this.shippingAddress,
    required this.openingBalance,
    this.paymentTerms,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? '',
      companyName: json['company_name'] as String? ?? json['companyName'] as String?,
      email: json['email'] as String? ?? json['email'] as String?,
      phone: json['phone'] as String? ?? json['phone'] as String?,
      gstin: json['gstin'] as String? ?? json['gstin'] as String?,
      pan: json['pan'] as String? ?? json['pan'] as String?,
      billingAddress: json['billing_address'] as String? ?? json['billingAddress'] as String?,
      shippingAddress: json['shipping_address'] as String? ?? json['shippingAddress'] as String?,
      openingBalance: json['opening_balance'] != null
          ? double.tryParse(json['opening_balance'].toString()) ?? 0.0
          : 0.0,
      paymentTerms: json['payment_terms'] as String? ?? json['paymentTerms'] as String?,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'gstin': gstin,
      'pan': pan,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'opening_balance': openingBalance,
      'payment_terms': paymentTerms,
      'status': status,
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
