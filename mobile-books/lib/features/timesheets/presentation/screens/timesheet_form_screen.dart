import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/projects/data/models/project.dart';
import 'package:mobile_books/features/projects/data/services/project_service.dart';
import 'package:mobile_books/features/timesheets/data/models/timesheet.dart';
import 'package:mobile_books/features/timesheets/presentation/providers/timesheet_provider.dart';
import 'package:mobile_books/features/timesheets/data/services/timesheet_service.dart';

class TimesheetFormScreen extends ConsumerStatefulWidget {
  final int? timesheetId;

  const TimesheetFormScreen({super.key, this.timesheetId});

  @override
  ConsumerState<TimesheetFormScreen> createState() => _TimesheetFormScreenState();
}

class _TimesheetFormScreenState extends ConsumerState<TimesheetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  final _hoursController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _projectId;
  DateTime? _workDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _billingType = 'Billable';
  String _status = 'Draft';
  double _billableAmount = 0.0;
  String? _timesheetNumber;
  int? _invoiceId;

  List<Project> _projects = [];
  bool _loadingProjects = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.timesheetId != null;
    _loadProjects();
    if (_isEdit) {
      _loadTimesheetData();
    } else {
      _workDate = DateTime.now();
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final projects = await ref.read(projectServiceProvider).getProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _loadingProjects = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProjects = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading projects: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _loadTimesheetData() async {
    setState(() => _isLoading = true);
    try {
      final ts = await ref.read(timesheetServiceProvider).getTimesheetById(widget.timesheetId!);
      if (!mounted) return;
      setState(() {
        _projectId = ts.projectId;
        _workDate = ts.workDate;
        _startTime = _parseTimeString(ts.startTime);
        _endTime = _parseTimeString(ts.endTime);
        _hoursController.text = ts.hours.toString();
        _billingType = ts.billingType;
        _hourlyRateController.text = ts.hourlyRate.toString();
        _descriptionController.text = ts.description ?? '';
        _status = ts.status;
        _billableAmount = ts.billableAmount;
        _timesheetNumber = ts.timesheetNumber;
        _invoiceId = ts.invoiceId;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading timesheet: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _calculateHours() {
    if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      double diffHours = (endMinutes - startMinutes) / 60.0;
      if (diffHours < 0) {
        diffHours = 0;
      }
      _hoursController.text = diffHours.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_status != 'Draft') return;
    final initialDate = _workDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _workDate = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    if (_status != 'Draft') return;
    final initialTime = isStart ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0)) : (_endTime ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _calculateHours();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final ts = Timesheet(
      id: widget.timesheetId ?? 0,
      userId: 0,
      projectId: _projectId!,
      workDate: _workDate ?? DateTime.now(),
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      hours: double.tryParse(_hoursController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      billingType: _billingType,
      hourlyRate: double.tryParse(_hourlyRateController.text.trim()) ?? 0.0,
      billableAmount: 0.0, // Server calculated
      status: _status,
    );

    try {
      if (_isEdit) {
        await ref.read(timesheetsProvider.notifier).updateTimesheet(
          widget.timesheetId!,
          ts.toJson(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timesheet updated successfully.')),
        );
      } else {
        await ref.read(timesheetsProvider.notifier).createTimesheet(ts);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timesheet created successfully.')),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving timesheet: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(timesheetsProvider.notifier).approveTimesheet(widget.timesheetId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timesheet approved successfully.')),
      );
      _loadTimesheetData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve timesheet: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(timesheetsProvider.notifier).cancelTimesheet(widget.timesheetId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timesheet cancelled successfully.')),
      );
      _loadTimesheetData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _convertToInvoice() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(timesheetsProvider.notifier).convertToInvoice(widget.timesheetId!);
      final invNumber = res['invoice']?['invoice_number'] as String?;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timesheet converted to invoice ${invNumber ?? ''} successfully.')),
      );
      _loadTimesheetData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to convert to invoice: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = _status == 'Draft';

    if (_isLoading && _isEdit) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit Timesheet' : 'New Timesheet')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Timesheet details${_timesheetNumber != null ? " ($_timesheetNumber)" : ""}' : 'New Timesheet'),
        actions: [
          if (isDraft)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isLoading ? null : _save,
            ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.m),
              children: [
                // Display Read-only Status Alert if not Draft
                if (!isDraft) ...[
                  Card(
                    color: _status == 'Cancelled'
                        ? AppColors.textSecondaryLight.withValues(alpha: 0.1)
                        : _status == 'Approved'
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Row(
                        children: [
                          Icon(
                            _status == 'Cancelled'
                                ? Icons.cancel
                                : _status == 'Approved'
                                    ? Icons.check_circle
                                    : Icons.description,
                            color: _status == 'Cancelled'
                                ? AppColors.textSecondaryLight
                                : _status == 'Approved'
                                    ? AppColors.success
                                    : AppColors.primaryBlue,
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Text(
                              'This timesheet is $_status. Fields cannot be edited.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _status == 'Cancelled'
                                    ? AppColors.textSecondaryLight
                                    : _status == 'Approved'
                                        ? AppColors.success
                                        : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],

                // Project Dropdown
                _loadingProjects
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                        child: LinearProgressIndicator(),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: ValueKey(_projectId),
                              initialValue: _projectId,
                              decoration: const InputDecoration(labelText: 'Project *'),
                              isExpanded: true,
                              validator: (value) => value == null ? 'Project is required' : null,
                              onChanged: !isDraft
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _projectId = val;
                                        // Auto-fill hourly rate from selected project
                                        final project = _projects.firstWhere((p) => p.id == val);
                                        if (project.billingType == 'Hourly') {
                                          _hourlyRateController.text = project.hourlyRate.toString();
                                        } else {
                                          _hourlyRateController.text = '0.0';
                                        }
                                      });
                                    },
                              items: _projects.map((p) {
                                return DropdownMenuItem<int?>(
                                  value: p.id,
                                  child: Text(p.projectName),
                                );
                              }).toList(),
                            ),
                          ),
                          if (isDraft) ...[
                            const SizedBox(width: AppSpacing.s),
                            IconButton(
                              onPressed: _showAddProjectDialog,
                              icon: const Icon(Icons.add_task, color: AppColors.primaryBlue),
                              tooltip: 'Add Project',
                            ),
                          ],
                        ],
                      ),
                const SizedBox(height: AppSpacing.m),

                // Work Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Work Date: ${_workDate != null ? DateFormat('dd MMM yyyy').format(_workDate!) : 'Not Set'}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: AppSpacing.s),

                // Start Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Start Time: ${_startTime != null ? _formatTimeOfDay(_startTime)! : 'Not Set'}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _pickTime(isStart: true),
                ),
                const SizedBox(height: AppSpacing.s),

                // End Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'End Time: ${_endTime != null ? _formatTimeOfDay(_endTime)! : 'Not Set'}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _pickTime(isStart: false),
                ),
                const SizedBox(height: AppSpacing.m),

                // Hours
                TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(labelText: 'Hours *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  readOnly: !isDraft,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Hours is required';
                    if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Billing Type Dropdown
                DropdownButtonFormField<String>(
                  key: ValueKey(_billingType),
                  initialValue: _billingType,
                  decoration: const InputDecoration(labelText: 'Billing Type'),
                  onChanged: !isDraft
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _billingType = val);
                          }
                        },
                  items: const [
                    DropdownMenuItem(value: 'Billable', child: Text('Billable')),
                    DropdownMenuItem(value: 'Non-Billable', child: Text('Non-Billable')),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                // Hourly Rate
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: const InputDecoration(labelText: 'Hourly Rate *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  readOnly: !isDraft,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Hourly rate is required';
                    if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  readOnly: !isDraft,
                ),

                // Read-only billable amount (for edit mode)
                if (_isEdit) ...[
                  const SizedBox(height: AppSpacing.m),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Billable Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '₹${_billableAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Lifecycle actions for existing timesheets
                if (_isEdit) ...[
                  if (_status == 'Draft') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isLoading ? null : _approve,
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            onPressed: _isLoading ? null : _cancel,
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_status == 'Approved' && _billingType == 'Billable') ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _convertToInvoice,
                      child: const Text('Convert to Invoice'),
                    ),
                  ] else if (_status == 'Invoiced' && _invoiceId != null) ...[
                    Card(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Center(
                          child: Text(
                            'Linked Invoice ID: $_invoiceId',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // ─── Inline Add Project Dialog ─────────────────────────────
  Future<void> _showAddProjectDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<Project>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Project Name *'),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Project name is required'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              try {
                final proj = await ref.read(projectServiceProvider).createProject(
                      Project(
                        id: 0,
                        userId: 0,
                        projectName: nameCtrl.text.trim(),
                        budget: 0.0,
                        billingType: 'Fixed Cost',
                        hourlyRate: 0.0,
                        status: 'Active',
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx, proj);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _projects.add(result);
        _projectId = result.id;
        if (result.billingType == 'Hourly') {
          _hourlyRateController.text = result.hourlyRate.toString();
        } else {
          _hourlyRateController.text = '0.0';
        }
      });
    }
  }
}
