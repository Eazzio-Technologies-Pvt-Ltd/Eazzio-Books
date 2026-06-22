import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/projects/data/models/project.dart';
import 'package:mobile_books/features/projects/data/services/project_service.dart';
import 'package:mobile_books/features/projects/presentation/providers/project_provider.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/data/services/customer_service.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final int? projectId;

  const ProjectFormScreen({super.key, this.projectId});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  final _projectNameController = TextEditingController();
  final _projectCodeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = 'Active';
  String _billingType = 'Fixed Cost';
  int? _customerId;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Customer> _customers = [];
  bool _loadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.projectId != null;
    _loadCustomers();
    if (_isEdit) {
      _loadProjectData();
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    try {
      final customerService = ref.read(customerServiceProvider);
      final customers = await customerService.getCustomers();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    try {
      final project = await ref.read(projectServiceProvider).getProjectById(widget.projectId!);
      _projectNameController.text = project.projectName;
      _projectCodeController.text = project.projectCode ?? '';
      _hourlyRateController.text = project.hourlyRate.toString();
      _budgetController.text = project.budget.toString();
      _descriptionController.text = project.description ?? '';
      _status = project.status;
      _billingType = project.billingType;
      _customerId = project.customerId;
      _startDate = project.startDate;
      _endDate = project.endDate;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading project: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectCodeController.dispose();
    _hourlyRateController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final projectData = Project(
      id: widget.projectId ?? 0,
      userId: 0, // Assigned by server
      customerId: _customerId,
      projectName: _projectNameController.text.trim(),
      projectCode: _projectCodeController.text.trim().isEmpty ? null : _projectCodeController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      budget: double.tryParse(_budgetController.text.trim()) ?? 0.0,
      billingType: _billingType,
      hourlyRate: _billingType == 'Hourly'
          ? (double.tryParse(_hourlyRateController.text.trim()) ?? 0.0)
          : 0.0,
      status: _status,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    try {
      if (_isEdit) {
        await ref.read(projectsProvider.notifier).updateProject(
          widget.projectId!,
          projectData.toJson(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully.')),
        );
      } else {
        await ref.read(projectsProvider.notifier).createProject(projectData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully.')),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving project: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _isEdit) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit Project' : 'New Project')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Project' : 'New Project'),
        actions: [
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
                // Project Name (required)
                TextFormField(
                  controller: _projectNameController,
                  decoration: const InputDecoration(labelText: 'Project Name *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Project name is required' : null,
                ),
                const SizedBox(height: AppSpacing.m),

                // Customer Dropdown (required)
                _loadingCustomers
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonFormField<int?>(
                        value: _customerId,
                        decoration: const InputDecoration(labelText: 'Customer *'),
                        validator: (value) => value == null ? 'Customer is required' : null,
                        items: _customers.map((customer) {
                          return DropdownMenuItem<int?>(
                            value: customer.id,
                            child: Text(customer.formattedName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _customerId = val);
                        },
                      ),
                const SizedBox(height: AppSpacing.m),

                // Project Code (optional)
                TextFormField(
                  controller: _projectCodeController,
                  decoration: const InputDecoration(labelText: 'Project Code'),
                ),
                const SizedBox(height: AppSpacing.m),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'On Hold', child: Text('On Hold')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _status = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Start Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Start Date: ${_startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : 'Not Set'}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: AppSpacing.s),

                // End Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'End Date: ${_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'Not Set'}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(isStart: false),
                ),
                const SizedBox(height: AppSpacing.m),

                // Billing Type Dropdown
                DropdownButtonFormField<String>(
                  value: _billingType,
                  decoration: const InputDecoration(labelText: 'Billing Type'),
                  items: const [
                    DropdownMenuItem(value: 'Fixed Cost', child: Text('Fixed Cost')),
                    DropdownMenuItem(value: 'Hourly', child: Text('Hourly')),
                    DropdownMenuItem(value: 'Non-Billable', child: Text('Non-Billable')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _billingType = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Hourly Rate (only visible when billingType == 'Hourly')
                if (_billingType == 'Hourly') ...[
                  TextFormField(
                    controller: _hourlyRateController,
                    decoration: const InputDecoration(labelText: 'Hourly Rate *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (_billingType != 'Hourly') return null;
                      if (value == null || value.trim().isEmpty) return 'Hourly rate is required';
                      if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],

                // Budget
                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(labelText: 'Budget'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.m),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
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
}
