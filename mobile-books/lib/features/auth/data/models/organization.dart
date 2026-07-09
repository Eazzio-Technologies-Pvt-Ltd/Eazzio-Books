class Organization {
  final int id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final String planId;
  final DateTime? subscriptionExpiresAt;
  final String subscriptionStatus;
  final int remainingTrialDays;
  final String organizationStatus;

  Organization({
    required this.id,
    required this.name,
    required this.isActive,
    this.createdAt,
    this.planId = 'trial',
    this.subscriptionExpiresAt,
    this.subscriptionStatus = 'active',
    this.remainingTrialDays = 0,
    this.organizationStatus = 'active',
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
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

    return Organization(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: parsedCreatedAt,
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
      'name': name,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'plan_id': planId,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'subscription_status': subscriptionStatus,
      'remaining_trial_days': remainingTrialDays,
      'organization_status': organizationStatus,
    };
  }

  Organization copyWith({
    int? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    String? planId,
    DateTime? subscriptionExpiresAt,
    String? subscriptionStatus,
    int? remainingTrialDays,
    String? organizationStatus,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      planId: planId ?? this.planId,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      remainingTrialDays: remainingTrialDays ?? this.remainingTrialDays,
      organizationStatus: organizationStatus ?? this.organizationStatus,
    );
  }

  @override
  String toString() {
    return 'Organization(id: $id, name: $name, isActive: $isActive, createdAt: $createdAt, planId: $planId, subscriptionExpiresAt: $subscriptionExpiresAt, subscriptionStatus: $subscriptionStatus, remainingTrialDays: $remainingTrialDays, organizationStatus: $organizationStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
        other.id == id &&
        other.name == name &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
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
      name,
      isActive,
      createdAt,
      planId,
      subscriptionExpiresAt,
      subscriptionStatus,
      remainingTrialDays,
      organizationStatus,
    );
  }
}
