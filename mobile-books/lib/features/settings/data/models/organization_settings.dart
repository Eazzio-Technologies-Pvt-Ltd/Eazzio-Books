class OrganizationSettings {
  final String organizationName;
  final String? businessType;
  final String? gstin;
  final String? pan;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? phone;
  final String? organizationEmail;
  final String financialYearStart;
  final String defaultCurrency;

  OrganizationSettings({
    required this.organizationName,
    this.businessType,
    this.gstin,
    this.pan,
    this.address,
    this.city,
    this.state,
    this.country,
    this.phone,
    this.organizationEmail,
    required this.financialYearStart,
    required this.defaultCurrency,
  });

  factory OrganizationSettings.fromJson(Map<String, dynamic> json) {
    return OrganizationSettings(
      organizationName: json['organization_name'] as String? ?? '',
      businessType: json['business_type'] as String?,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      organizationEmail: json['organization_email'] as String?,
      financialYearStart: json['financial_year_start'] as String? ?? 'April',
      defaultCurrency: json['default_currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_name': organizationName,
      'business_type': businessType,
      'gstin': gstin,
      'pan': pan,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'phone': phone,
      'organization_email': organizationEmail,
      'financial_year_start': financialYearStart,
      'default_currency': defaultCurrency,
    };
  }

  OrganizationSettings copyWith({
    String? organizationName,
    String? businessType,
    String? gstin,
    String? pan,
    String? address,
    String? city,
    String? state,
    String? country,
    String? phone,
    String? organizationEmail,
    String? financialYearStart,
    String? defaultCurrency,
  }) {
    return OrganizationSettings(
      organizationName: organizationName ?? this.organizationName,
      businessType: businessType ?? this.businessType,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      organizationEmail: organizationEmail ?? this.organizationEmail,
      financialYearStart: financialYearStart ?? this.financialYearStart,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    );
  }
}
