class Organization {
  final int id;
  final String name;
  final String businessType;
  final int ownerId;
  final String defaultCurrency;

  Organization({
    required this.id,
    required this.name,
    required this.businessType,
    required this.ownerId,
    required this.defaultCurrency,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['organization_name'] as String? ?? '',
      businessType: json['business_type'] as String? ?? 'Other',
      ownerId: json['owner_id'] as int? ?? 0,
      defaultCurrency: json['default_currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'business_type': businessType,
      'owner_id': ownerId,
      'default_currency': defaultCurrency,
    };
  }

  @override
  String toString() {
    return 'Organization(id: $id, name: $name, businessType: $businessType, ownerId: $ownerId, defaultCurrency: $defaultCurrency)';
  }
}
