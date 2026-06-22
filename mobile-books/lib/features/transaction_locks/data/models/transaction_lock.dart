class TransactionLock {
  final int id;
  final int userId;
  final String lockName;
  final DateTime lockDate;
  final String? reason;
  final List<String> lockedModules;
  final bool isActive;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionLock({
    required this.id,
    required this.userId,
    required this.lockName,
    required this.lockDate,
    this.reason,
    required this.lockedModules,
    required this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionLock.fromJson(Map<String, dynamic> json) {
    return TransactionLock(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      lockName: json['lock_name'] as String? ?? json['lockName'] as String? ?? '',
      lockDate: json['lock_date'] != null
          ? DateTime.parse(json['lock_date'] as String)
          : DateTime.now(),
      reason: json['reason'] as String?,
      lockedModules: (json['locked_modules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? false,
      createdBy: json['created_by'] as int? ?? json['createdBy'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lock_name': lockName,
      'lock_date': lockDate.toIso8601String().split('T')[0],
      'reason': reason,
      'locked_modules': lockedModules,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TransactionLock copyWith({
    int? id,
    int? userId,
    String? lockName,
    DateTime? lockDate,
    String? reason,
    List<String>? lockedModules,
    bool? isActive,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionLock(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lockName: lockName ?? this.lockName,
      lockDate: lockDate ?? this.lockDate,
      reason: reason ?? this.reason,
      lockedModules: lockedModules ?? this.lockedModules,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
