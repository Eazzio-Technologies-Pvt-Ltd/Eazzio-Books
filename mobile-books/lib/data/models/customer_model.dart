class CustomerModel {
  final int id;
  final String customerType; // Business, Individual
  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? mobile;
  final String currency;
  final double openingBalance;
  final String? paymentTerms;
  final String? pan;
  final String? remarks;

  CustomerModel({
    required this.id,
    required this.customerType,
    this.salutation,
    this.firstName,
    this.lastName,
    this.companyName,
    this.displayName,
    this.email,
    this.phone,
    this.mobile,
    required this.currency,
    required this.openingBalance,
    this.paymentTerms,
    this.pan,
    this.remarks,
  });

  String get printableName {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (companyName != null && companyName!.isNotEmpty) return companyName!;
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unnamed Customer';
    return '$salutation $first $last'.trim();
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      customerType: json['customer_type'] as String? ?? 'Business',
      salutation: json['salutation'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      companyName: json['company_name'] as String?,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      openingBalance: (json['opening_balance'] as num? ?? 0.0).toDouble(),
      paymentTerms: json['payment_terms'] as String?,
      pan: json['pan'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_type': customerType,
      'salutation': salutation,
      'first_name': firstName,
      'last_name': lastName,
      'company_name': companyName,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'currency': currency,
      'opening_balance': openingBalance,
      'payment_terms': paymentTerms,
      'pan': pan,
      'remarks': remarks,
    };
  }
}
