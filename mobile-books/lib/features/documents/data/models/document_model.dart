class DocumentModel {
  final int id;
  final int userId;
  final String documentName;
  final String? category;
  final String? relatedModule;
  final int? relatedRecordId;
  final String? fileName;
  final String? filePath;
  final String? fileType;
  final int? fileSize;
  final String? notes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.documentName,
    this.category,
    this.relatedModule,
    this.relatedRecordId,
    this.fileName,
    this.filePath,
    this.fileType,
    this.fileSize,
    this.notes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      documentName: json['document_name'] as String,
      category: json['category'] as String?,
      relatedModule: json['related_module'] as String?,
      relatedRecordId: json['related_record_id'] as int?,
      fileName: json['file_name'] as String?,
      filePath: json['file_path'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      notes: json['notes'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_name': documentName,
      'category': category,
      'related_module': relatedModule,
      'related_record_id': relatedRecordId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'notes': notes,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
