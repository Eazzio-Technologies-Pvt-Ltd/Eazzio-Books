class Project {
  final int id;
  final int userId;
  final int? customerId;
  final String projectName;
  final String? projectCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budget;
  final String billingType; // 'Fixed Cost', etc.
  final double hourlyRate;
  final String status; // 'Active', 'Completed', etc.
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.userId,
    this.customerId,
    required this.projectName,
    this.projectCode,
    this.startDate,
    this.endDate,
    required this.budget,
    required this.billingType,
    required this.hourlyRate,
    required this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      customerId: json['customer_id'] as int? ?? json['customerId'] as int?,
      projectName: json['project_name'] as String? ?? json['projectName'] as String? ?? '',
      projectCode: json['project_code'] as String? ?? json['projectCode'] as String?,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      budget: (json['budget'] as num? ?? 0.0).toDouble(),
      billingType: json['billing_type'] as String? ?? json['billingType'] as String? ?? 'Fixed Cost',
      hourlyRate: (json['hourly_rate'] as num? ?? json['hourlyRate'] as num? ?? 0.0).toDouble(),
      status: json['status'] as String? ?? 'Active',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'project_name': projectName,
      'project_code': projectCode,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'budget': budget,
      'billing_type': billingType,
      'hourly_rate': hourlyRate,
      'status': status,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Project copyWith({
    int? id,
    int? userId,
    int? customerId,
    String? projectName,
    String? projectCode,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? billingType,
    double? hourlyRate,
    String? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      projectName: projectName ?? this.projectName,
      projectCode: projectCode ?? this.projectCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      billingType: billingType ?? this.billingType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
