class CustomerActivity {
  final int id;
  final int customerId;
  final int userId;
  final String actionType;
  final String description;
  final DateTime? createdAt;
  final String? userEmail;

  CustomerActivity({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.actionType,
    required this.description,
    this.createdAt,
    this.userEmail,
  });

  factory CustomerActivity.fromJson(Map<String, dynamic> json) {
    return CustomerActivity(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      userId: json['user_id'] as int,
      actionType: json['action_type'] as String? ?? 'updated',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      userEmail: json['user_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'user_id': userId,
      'action_type': actionType,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'user_email': userEmail,
    };
  }

  @override
  String toString() {
    return 'CustomerActivity(id: $id, actionType: $actionType, desc: $description)';
  }
}
