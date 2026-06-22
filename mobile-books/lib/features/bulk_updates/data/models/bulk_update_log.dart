class BulkUpdateLog {
  final int id;
  final int userId;
  final String moduleName;
  final String actionType;
  final int selectedRecordCount;
  final int successCount;
  final int failedCount;
  final Map<String, dynamic>? requestPayload;
  final Map<String, dynamic>? resultSummary;
  final DateTime createdAt;

  BulkUpdateLog({
    required this.id,
    required this.userId,
    required this.moduleName,
    required this.actionType,
    required this.selectedRecordCount,
    required this.successCount,
    required this.failedCount,
    this.requestPayload,
    this.resultSummary,
    required this.createdAt,
  });

  factory BulkUpdateLog.fromJson(Map<String, dynamic> json) {
    return BulkUpdateLog(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      moduleName: json['module_name'] as String,
      actionType: json['action_type'] as String,
      selectedRecordCount: json['selected_record_count'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      requestPayload: json['request_payload'] is Map<String, dynamic>
          ? json['request_payload'] as Map<String, dynamic>
          : null,
      resultSummary: json['result_summary'] is Map<String, dynamic>
          ? json['result_summary'] as Map<String, dynamic>
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'module_name': moduleName,
      'action_type': actionType,
      'selected_record_count': selectedRecordCount,
      'success_count': successCount,
      'failed_count': failedCount,
      'request_payload': requestPayload,
      'result_summary': resultSummary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
