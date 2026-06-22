class Salesperson {
  final int id;
  final int userId;
  final String name;
  final String? email;
  final String? phone;
  final String? employeeId;
  final DateTime? createdAt;

  Salesperson({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    this.employeeId,
    this.createdAt,
  });

  factory Salesperson.fromJson(Map<String, dynamic> json) {
    return Salesperson(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      name: json['name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      employeeId: json['employee_id'] as String? ?? json['employeeId'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'employee_id': employeeId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Salesperson copyWith({
    int? id,
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? employeeId,
    DateTime? createdAt,
  }) {
    return Salesperson(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
