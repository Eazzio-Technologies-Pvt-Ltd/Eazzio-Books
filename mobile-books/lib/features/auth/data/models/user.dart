class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final int organizationId;
  final String? organizationName;
  final String businessType;
  final String planId;
  final DateTime? subscriptionExpiresAt;
  final String subscriptionStatus;
  final int remainingTrialDays;
  final String organizationStatus;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.organizationId,
    this.organizationName,
    required this.businessType,
    this.planId = 'trial',
    this.subscriptionExpiresAt,
    this.subscriptionStatus = 'active',
    this.remainingTrialDays = 0,
    this.organizationStatus = 'active',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var parsedPlanId = json['plan_id'] as String? ?? json['planId'] as String? ?? 'trial';
    var parsedExpiresAt = json['subscription_expires_at'] != null
        ? DateTime.tryParse(json['subscription_expires_at'] as String)
        : (json['subscriptionExpiresAt'] != null 
            ? DateTime.tryParse(json['subscriptionExpiresAt'] as String)
            : null);
    
    final parsedCreatedAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : (json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null);

    // Calculate remaining trial days & status
    int remaining = 0;
    String status = json['subscription_status'] as String? ?? json['subscriptionStatus'] as String? ?? '';

    if (parsedPlanId == 'free' || parsedPlanId == 'trial') {
      final baseDate = parsedCreatedAt ?? DateTime.now();
      final trialExpiresAt = baseDate.add(const Duration(days: 14));
      final now = DateTime.now();
      parsedPlanId = 'trial';
      parsedExpiresAt = trialExpiresAt;
      
      if (now.isBefore(trialExpiresAt)) {
        status = 'trialing';
        remaining = trialExpiresAt.difference(now).inDays;
      } else {
        status = 'expired';
        remaining = 0;
      }
    } else {
      if (parsedExpiresAt != null) {
        final difference = parsedExpiresAt.difference(DateTime.now()).inDays;
        remaining = difference > 0 ? difference : 0;
      }
      
      if (status.isEmpty) {
        if (parsedExpiresAt == null) {
          status = 'expired';
        } else if (parsedExpiresAt.isAfter(DateTime.now())) {
          status = 'active';
        } else {
          status = 'expired';
        }
      }
    }

    final orgStatus = json['organization_status'] as String? ?? 
                      json['organizationStatus'] as String? ?? 
                      ((json['is_active'] as bool? ?? true) ? 'active' : 'inactive');

    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'Admin',
      organizationId: json['organization_id'] as int? ?? json['organizationId'] as int? ?? 0,
      organizationName: json['organization_name'] as String? ?? json['organizationName'] as String?,
      businessType: json['business_type'] as String? ?? json['businessType'] as String? ?? 'Other',
      planId: parsedPlanId,
      subscriptionExpiresAt: parsedExpiresAt,
      subscriptionStatus: status,
      remainingTrialDays: json['remaining_trial_days'] as int? ?? json['remainingTrialDays'] as int? ?? remaining,
      organizationStatus: orgStatus,
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
      'plan_id': planId,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'subscription_status': subscriptionStatus,
      'remaining_trial_days': remainingTrialDays,
      'organization_status': organizationStatus,
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
    String? planId,
    DateTime? subscriptionExpiresAt,
    String? subscriptionStatus,
    int? remainingTrialDays,
    String? organizationStatus,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      businessType: businessType ?? this.businessType,
      planId: planId ?? this.planId,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      remainingTrialDays: remainingTrialDays ?? this.remainingTrialDays,
      organizationStatus: organizationStatus ?? this.organizationStatus,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role, organizationId: $organizationId, organizationName: $organizationName, businessType: $businessType, planId: $planId, subscriptionExpiresAt: $subscriptionExpiresAt, subscriptionStatus: $subscriptionStatus, remainingTrialDays: $remainingTrialDays, organizationStatus: $organizationStatus)';
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
        other.businessType == businessType &&
        other.planId == planId &&
        other.subscriptionExpiresAt == subscriptionExpiresAt &&
        other.subscriptionStatus == subscriptionStatus &&
        other.remainingTrialDays == remainingTrialDays &&
        other.organizationStatus == organizationStatus;
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
      planId,
      subscriptionExpiresAt,
      subscriptionStatus,
      remainingTrialDays,
      organizationStatus,
    );
  }
}
