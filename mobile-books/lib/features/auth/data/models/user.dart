class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final int organizationId;
  final String? organizationName;
  final String businessType;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.organizationId,
    this.organizationName,
    required this.businessType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'Admin',
      organizationId: json['organization_id'] as int? ?? json['organizationId'] as int? ?? 0,
      organizationName: json['organization_name'] as String? ?? json['organizationName'] as String?,
      businessType: json['business_type'] as String? ?? json['businessType'] as String? ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'organization_id': organizationId,
      'organization_name': organizationName,
      'business_type': businessType,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? role,
    int? organizationId,
    String? organizationName,
    String? businessType,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      businessType: businessType ?? this.businessType,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role, organizationId: $organizationId, organizationName: $organizationName, businessType: $businessType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.fullName == fullName &&
        other.role == role &&
        other.organizationId == organizationId &&
        other.organizationName == organizationName &&
        other.businessType == businessType;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      fullName,
      role,
      organizationId,
      organizationName,
      businessType,
    );
  }
}
