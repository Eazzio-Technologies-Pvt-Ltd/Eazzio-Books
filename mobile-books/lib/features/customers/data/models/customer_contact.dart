class CustomerContact {
  final int? id;
  final int? customerId;
  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? workPhone;
  final String? mobile;

  CustomerContact({
    this.id,
    this.customerId,
    this.salutation,
    this.firstName,
    this.lastName,
    this.email,
    this.workPhone,
    this.mobile,
  });

  factory CustomerContact.fromJson(Map<String, dynamic> json) {
    return CustomerContact(
      id: json['id'] as int?,
      customerId: json['customer_id'] as int?,
      salutation: json['salutation'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      workPhone: json['work_phone'] as String?,
      mobile: json['mobile'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      'salutation': salutation,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'work_phone': workPhone,
      'mobile': mobile,
    };
  }

  CustomerContact copyWith({
    int? id,
    int? customerId,
    String? salutation,
    String? firstName,
    String? lastName,
    String? email,
    String? workPhone,
    String? mobile,
  }) {
    return CustomerContact(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salutation: salutation ?? this.salutation,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      workPhone: workPhone ?? this.workPhone,
      mobile: mobile ?? this.mobile,
    );
  }

  String get fullName {
    final parts = [
      if (salutation != null && salutation!.isNotEmpty) salutation,
      if (firstName != null && firstName!.isNotEmpty) firstName,
      if (lastName != null && lastName!.isNotEmpty) lastName,
    ];
    return parts.join(' ');
  }

  @override
  String toString() {
    return 'CustomerContact(id: $id, email: $email, name: $fullName)';
  }
}
