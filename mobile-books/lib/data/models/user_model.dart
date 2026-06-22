class UserModel {
  final int id;
  final String email;
  final String role;
  final int? organizationId;
  final String? fullName;
  final String? organizationName;
  final String? businessType;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.organizationId,
    this.fullName,
    this.organizationName,
    this.businessType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'Admin',
      organizationId: json['organization_id'] as int?,
      fullName: json['full_name'] as String?,
      organizationName: json['organization_name'] as String?,
      businessType: json['business_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'organization_id': organizationId,
      'full_name': fullName,
      'organization_name': organizationName,
      'business_type': businessType,
    };
  }
}
