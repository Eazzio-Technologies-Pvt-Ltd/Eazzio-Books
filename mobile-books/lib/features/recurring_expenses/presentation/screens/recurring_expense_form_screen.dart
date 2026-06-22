import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/recurring_expenses/data/models/recurring_expense.dart';
import 'package:mobile_books/features/recurring_expenses/presentation/providers/recurring_expense_provider.dart';

class RecurringExpenseFormScreen extends ConsumerStatefulWidget {
  final int? expenseId;

  const RecurringExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<RecurringExpenseFormScreen> createState() => _RecurringExpenseFormScreenState();
}

class _RecurringExpenseFormScreenState extends ConsumerState<RecurringExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'General Expense';
  String _frequency = 'Monthly';
  String _status = 'Active';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  final List<String> _categories = [
    'General Expense',
    'Rent Expense',
    'Office Supplies',
    'Travel Expenses',
    'Advertising & Marketing',
    'Salaries & Wages',
    'Meals and Entertainment',
    'Utilities',
  ];

  final List<String> _frequencies = ['Monthly', 'Quarterly', 'Yearly'];
  final List<String> _statuses = ['Active', 'Paused', 'Stopped'];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expenseId != null;
    if (_isEdit) {
      _loadExpenseData();
    }
  }

  Future<void> _loadExpenseData() async {
    setState(() => _isLoading = true);
    try {
      final expense = await ref.read(recurringExpenseDetailsProvider(widget.expenseId!).future);
      _nameController.text = expense.expenseName;
      _category = _categories.contains(expense.category) ? expense.category : 'General Expense';
      _amountController.text = expense.amount.toString();
      _frequency = _frequencies.contains(expense.frequency) ? expense.frequency : 'Monthly';
      _dueDayController.text = expense.dueDay.toString();
      _startDate = expense.startDate;
      _endDate = expense.endDate;
      _status = _statuses.contains(expense.status) ? expense.status : 'Active';
      _notesController.text = expense.notes ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recurring expense: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final dueDay = int.tryParse(_dueDayController.text.trim()) ?? 1;

    final expense = RecurringExpense(
      id: widget.expenseId ?? 0,
      expenseName: name,
      category: _category,
      amount: amount,
      frequency: _frequency,
      dueDay: dueDay,
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      notes: _notesController.text.trim(),
      createdBy: 0, // Server-assigned
    );

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(recurringExpensesProvider.notifier);
      if (_isEdit) {
        await notifier.updateRecurringExpense(widget.expenseId!, expense);
      } else {
        await notifier.createRecurringExpense(expense);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Recurring expense updated' : 'Recurring expense created')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('dd MMM yyyy').format(_startDate);
    final endStr = _endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'None';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Recurring Expense' : 'New Recurring Expense'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name *',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Category
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) *',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Amount is required';
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Frequency
                    DropdownButtonFormField<String>(
                      initialValue: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency *',
                      ),
                      items: _frequencies.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _frequency = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Due Day
                    TextFormField(
                      controller: _dueDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Due Day (1-31) *',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Due day is required';
                        final numVal = int.tryParse(val.trim());
                        if (numVal == null || numVal < 1 || numVal > 31) return 'Enter a day between 1 and 31';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Dates row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date *',
                              ),
                              child: Text(startStr),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                suffixIcon: _endDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () => setState(() => _endDate = null),
                                      )
                                    : null,
                              ),
                              child: Text(endStr),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Status
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                      ),
                      items: _statuses.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Expense'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
