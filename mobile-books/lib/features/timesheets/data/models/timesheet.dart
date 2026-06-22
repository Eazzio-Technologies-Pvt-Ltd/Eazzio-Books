class Timesheet {
  final int id;
  final int userId;
  final int projectId;
  final int? customerId;
  final int? staffId;
  final String? timesheetNumber;
  final DateTime workDate;
  final String? startTime;
  final String? endTime;
  final double hours;
  final String? description;
  final String billingType; // 'Billable', 'Non-Billable'
  final double hourlyRate;
  final double billableAmount;
  final String status; // 'Draft', 'Approved', 'Invoiced', 'Cancelled'
  final int? invoiceId;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // JOIN fields (read-only from server)
  final String? projectName;
  final String? customerName;
  final String? staffName;

  Timesheet({
    required this.id,
    required this.userId,
    required this.projectId,
    this.customerId,
    this.staffId,
    this.timesheetNumber,
    required this.workDate,
    this.startTime,
    this.endTime,
    required this.hours,
    this.description,
    required this.billingType,
    required this.hourlyRate,
    required this.billableAmount,
    required this.status,
    this.invoiceId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.projectName,
    this.customerName,
    this.staffName,
  });

  factory Timesheet.fromJson(Map<String, dynamic> json) {
    return Timesheet(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      projectId: json['project_id'] as int? ?? json['projectId'] as int? ?? 0,
      customerId: json['customer_id'] as int? ?? json['customerId'] as int?,
      staffId: json['staff_id'] as int? ?? json['staffId'] as int?,
      timesheetNumber: json['timesheet_number'] as String? ?? json['timesheetNumber'] as String?,
      workDate: json['work_date'] != null
          ? DateTime.tryParse(json['work_date'] as String) ?? DateTime.now()
          : (json['workDate'] != null
              ? DateTime.tryParse(json['workDate'] as String) ?? DateTime.now()
              : DateTime.now()),
      startTime: json['start_time'] as String? ?? json['startTime'] as String?,
      endTime: json['end_time'] as String? ?? json['endTime'] as String?,
      hours: (json['hours'] as num? ?? 0.0).toDouble(),
      description: json['description'] as String?,
      billingType: json['billing_type'] as String? ?? json['billingType'] as String? ?? 'Billable',
      hourlyRate: (json['hourly_rate'] as num? ?? json['hourlyRate'] as num? ?? 0.0).toDouble(),
      billableAmount: (json['billable_amount'] as num? ?? json['billableAmount'] as num? ?? 0.0).toDouble(),
      status: json['status'] as String? ?? 'Draft',
      invoiceId: json['invoice_id'] as int? ?? json['invoiceId'] as int?,
      createdBy: json['created_by']?.toString() ?? json['createdBy']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      projectName: json['project_name'] as String? ?? json['projectName'] as String?,
      customerName: json['customer_name'] as String? ?? json['customerName'] as String?,
      staffName: json['staff_name'] as String? ?? json['staffName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      if (staffId != null) 'staff_id': staffId,
      if (timesheetNumber != null) 'timesheet_number': timesheetNumber,
      'work_date': workDate.toIso8601String().split('T')[0],
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      'hours': hours,
      if (description != null) 'description': description,
      'billing_type': billingType,
      'hourly_rate': hourlyRate,
      'status': status,
      if (invoiceId != null) 'invoice_id': invoiceId,
    };
  }

  Timesheet copyWith({
    int? id,
    int? userId,
    int? projectId,
    int? customerId,
    int? staffId,
    String? timesheetNumber,
    DateTime? workDate,
    String? startTime,
    String? endTime,
    double? hours,
    String? description,
    String? billingType,
    double? hourlyRate,
    double? billableAmount,
    String? status,
    int? invoiceId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? projectName,
    String? customerName,
    String? staffName,
  }) {
    return Timesheet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      customerId: customerId ?? this.customerId,
      staffId: staffId ?? this.staffId,
      timesheetNumber: timesheetNumber ?? this.timesheetNumber,
      workDate: workDate ?? this.workDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      billingType: billingType ?? this.billingType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      billableAmount: billableAmount ?? this.billableAmount,
      status: status ?? this.status,
      invoiceId: invoiceId ?? this.invoiceId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      projectName: projectName ?? this.projectName,
      customerName: customerName ?? this.customerName,
      staffName: staffName ?? this.staffName,
    );
  }
}
