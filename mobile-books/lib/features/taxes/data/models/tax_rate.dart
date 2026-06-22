class TaxRate {
  final int id;
  final int userId;
  final String taxName;
  final String taxType; // GST, IGST, CGST, SGST, CESS, Other
  final double rate;
  final String? description;
  final String status; // active, inactive
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaxRate({
    required this.id,
    required this.userId,
    required this.taxName,
    required this.taxType,
    required this.rate,
    this.description,
    required this.status,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      taxName: json['tax_name'] as String,
      taxType: json['tax_type'] as String? ?? 'Other',
      rate: double.tryParse(json['rate'].toString()) ?? 0.0,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tax_name': taxName,
      'tax_type': taxType,
      'rate': rate,
      'description': description,
      'status': status,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
