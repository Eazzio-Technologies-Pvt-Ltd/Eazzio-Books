int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

class CustomerAddress {
  final int? id;
  final int? customerId;
  final String type; // 'billing' or 'shipping'
  final String? attention;
  final String? country;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? phone;
  final String? fax;

  CustomerAddress({
    this.id,
    this.customerId,
    required this.type,
    this.attention,
    this.country,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pinCode,
    this.phone,
    this.fax,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: _parseInt(json['id']),
      customerId: _parseInt(json['customer_id']),
      type: json['type'] as String? ?? 'billing',
      attention: json['attention'] as String?,
      country: json['country'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pinCode: json['pin_code'] as String? ?? json['pincode'] as String?,
      phone: json['phone'] as String?,
      fax: json['fax'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      'type': type,
      'attention': attention,
      'country': country,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pin_code': pinCode,
      'phone': phone,
      'fax': fax,
    };
  }

  CustomerAddress copyWith({
    int? id,
    int? customerId,
    String? type,
    String? attention,
    String? country,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pinCode,
    String? phone,
    String? fax,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      attention: attention ?? this.attention,
      country: country ?? this.country,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
    );
  }

  @override
  String toString() {
    return 'CustomerAddress(id: $id, type: $type, city: $city, state: $state)';
  }
}
