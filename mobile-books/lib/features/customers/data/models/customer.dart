import 'package:mobile_books/features/customers/data/models/customer_address.dart';
import 'package:mobile_books/features/customers/data/models/customer_contact.dart';

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

class Customer {
  final int id;
  final String customerType;
  final String? customerSubType;
  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? workPhone;
  final String? mobile;
  final String? remarks;
  final String? pan;
  final String currency;
  final double openingBalance;
  final String? paymentTerms;
  final bool enablePortal;
  final String portalLanguage;
  final bool isActive;
  final int organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CustomerAddress> addresses;
  final List<CustomerContact> contacts;

  Customer({
    required this.id,
    required this.customerType,
    this.customerSubType,
    this.salutation,
    this.firstName,
    this.lastName,
    this.companyName,
    this.displayName,
    this.email,
    this.phone,
    this.workPhone,
    this.mobile,
    this.remarks,
    this.pan,
    required this.currency,
    required this.openingBalance,
    this.paymentTerms,
    required this.enablePortal,
    required this.portalLanguage,
    required this.isActive,
    required this.organizationId,
    this.createdAt,
    this.updatedAt,
    this.addresses = const [],
    this.contacts = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _parseInt(json['id']) ?? 0,
      customerType: json['customer_type'] as String? ?? 'Business',
      customerSubType: json['customer_sub_type'] as String?,
      salutation: json['salutation'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      companyName: json['company_name'] as String?,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      workPhone: json['work_phone'] as String?,
      mobile: json['mobile'] as String?,
      remarks: json['remarks'] as String?,
      pan: json['pan'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      openingBalance: _parseDouble(json['opening_balance']),
      paymentTerms: json['payment_terms'] as String?,
      enablePortal: json['enable_portal'] as bool? ?? false,
      portalLanguage: json['portal_language'] as String? ?? 'en',
      isActive: json['is_active'] as bool? ?? true,
      organizationId: _parseInt(json['organization_id']) ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      addresses: json['addresses'] != null
          ? (json['addresses'] as List)
              .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      contacts: json['contacts'] != null
          ? (json['contacts'] as List)
              .map((e) => CustomerContact.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_type': customerType,
      'customer_sub_type': customerSubType,
      'salutation': salutation,
      'first_name': firstName,
      'last_name': lastName,
      'company_name': companyName,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'work_phone': workPhone,
      'mobile': mobile,
      'remarks': remarks,
      'pan': pan,
      'currency': currency,
      'opening_balance': openingBalance,
      'payment_terms': paymentTerms,
      'enable_portal': enablePortal,
      'portal_language': portalLanguage,
      'is_active': isActive,
      'organization_id': organizationId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'addresses': addresses.map((e) => e.toJson()).toList(),
      'contacts': contacts.map((e) => e.toJson()).toList(),
    };
  }

  String get formattedName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    final nameParts = [
      if (salutation != null && salutation!.isNotEmpty) salutation,
      if (firstName != null && firstName!.isNotEmpty) firstName,
      if (lastName != null && lastName!.isNotEmpty) lastName,
    ];
    if (nameParts.isNotEmpty) return nameParts.join(' ');
    if (companyName != null && companyName!.isNotEmpty) return companyName!;
    return 'Customer #$id';
  }

  String? get billingAddress {
    if (addresses.isEmpty) return null;
    try {
      final billing = addresses.firstWhere((a) => a.type == 'billing');
      final parts = [
        if (billing.addressLine1 != null && billing.addressLine1!.isNotEmpty) billing.addressLine1,
        if (billing.addressLine2 != null && billing.addressLine2!.isNotEmpty) billing.addressLine2,
        if (billing.city != null && billing.city!.isNotEmpty) billing.city,
        if (billing.state != null && billing.state!.isNotEmpty) billing.state,
        if (billing.pinCode != null && billing.pinCode!.isNotEmpty) billing.pinCode,
      ];
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  String? get billingState {
    if (addresses.isEmpty) return null;
    try {
      return addresses.firstWhere((a) => a.type == 'billing').state;
    } catch (_) {
      return null;
    }
  }

  Customer copyWith({
    int? id,
    String? customerType,
    String? customerSubType,
    String? salutation,
    String? firstName,
    String? lastName,
    String? companyName,
    String? displayName,
    String? email,
    String? phone,
    String? workPhone,
    String? mobile,
    String? remarks,
    String? pan,
    String? currency,
    double? openingBalance,
    String? paymentTerms,
    bool? enablePortal,
    String? portalLanguage,
    bool? isActive,
    int? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CustomerAddress>? addresses,
    List<CustomerContact>? contacts,
  }) {
    return Customer(
      id: id ?? this.id,
      customerType: customerType ?? this.customerType,
      customerSubType: customerSubType ?? this.customerSubType,
      salutation: salutation ?? this.salutation,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyName: companyName ?? this.companyName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      workPhone: workPhone ?? this.workPhone,
      mobile: mobile ?? this.mobile,
      remarks: remarks ?? this.remarks,
      pan: pan ?? this.pan,
      currency: currency ?? this.currency,
      openingBalance: openingBalance ?? this.openingBalance,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      enablePortal: enablePortal ?? this.enablePortal,
      portalLanguage: portalLanguage ?? this.portalLanguage,
      isActive: isActive ?? this.isActive,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      addresses: addresses ?? this.addresses,
      contacts: contacts ?? this.contacts,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $formattedName, email: $email)';
  }
}
