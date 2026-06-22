class Tax {
  final int? id;
  final int? userId;
  final String taxName;
  final String taxType; // e.g. 'GST', 'CGST', 'SGST', 'IGST', 'Other'
  final double rate;
  final String? description;
  final String status; // 'active' or 'inactive'
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tax({
    this.id,
    this.userId,
    required this.taxName,
    required this.taxType,
    required this.rate,
    this.description,
    this.status = 'active',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      taxName: json['tax_name'] as String? ?? '',
      taxType: json['tax_type'] as String? ?? 'Other',
      rate: json['rate'] != null ? double.parse(json['rate'].toString()) : 0.0,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'tax_name': taxName,
      'tax_type': taxType,
      'rate': rate,
      'description': description,
      'status': status,
      'is_deleted': isDeleted,
    };
  }

  Tax copyWith({
    int? id,
    int? userId,
    String? taxName,
    String? taxType,
    double? rate,
    String? description,
    String? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tax(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taxName: taxName ?? this.taxName,
      taxType: taxType ?? this.taxType,
      rate: rate ?? this.rate,
      description: description ?? this.description,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
