class Organization {
  final int id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;

  Organization({
    required this.id,
    required this.name,
    required this.isActive,
    this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Organization copyWith({
    int? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Organization(id: $id, name: $name, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
        other.id == id &&
        other.name == name &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, isActive, createdAt);
  }
}
