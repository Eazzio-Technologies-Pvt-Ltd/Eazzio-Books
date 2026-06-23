import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/accounting/data/models/chart_of_account.dart';
import 'package:mobile_books/features/accounting/data/models/journal_entry.dart';
import 'package:mobile_books/features/accounting/data/models/journal_line.dart';
import 'package:mobile_books/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';
import 'package:mobile_books/widgets/common/unsaved_changes_dialog.dart';

class JournalLineInput {
  int? accountId;
  final descriptionController = TextEditingController();
  final debitController = TextEditingController();
  final creditController = TextEditingController();

  JournalLineInput({this.accountId});

  void dispose() {
    descriptionController.dispose();
    debitController.dispose();
    creditController.dispose();
  }
}

class ManualJournalFormScreen extends ConsumerStatefulWidget {
  final int? journalId; // null = create mode, otherwise edit mode

  const ManualJournalFormScreen({
    super.key,
    this.journalId,
  });

  @override
  ConsumerState<ManualJournalFormScreen> createState() => _ManualJournalFormScreenState();
}

class _ManualJournalFormScreenState extends ConsumerState<ManualJournalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _journalNumberController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _journalDate = DateTime.now();

  final List<JournalLineInput> _lineInputs = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.journalId != null;
    if (_isEditMode) {
      _loadJournalDetails();
    } else {
      // Add two empty starting lines (minimum required for a journal)
      _lineInputs.add(JournalLineInput());
      _lineInputs.add(JournalLineInput());
    }
  }

  @override
  void dispose() {
    _journalNumberController.dispose();
    _referenceNumberController.dispose();
    _notesController.dispose();
    for (final input in _lineInputs) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> _loadJournalDetails() async {
    setState(() => _isLoading = true);
    try {
      final journal = await ref.read(journalDetailsProvider(widget.journalId!).future);
      setState(() {
        _journalNumberController.text = journal.journalNumber;
        _referenceNumberController.text = journal.referenceNumber ?? '';
        _notesController.text = journal.notes ?? '';
        _journalDate = journal.journalDate;

        // Populate lines
        _lineInputs.clear();
        if (journal.lines != null) {
          for (final line in journal.lines!) {
            final input = JournalLineInput(accountId: line.accountId);
            input.descriptionController.text = line.description ?? '';
            input.debitController.text = line.debit > 0 ? line.debit.toString() : '';
            input.creditController.text = line.credit > 0 ? line.credit.toString() : '';
            _lineInputs.add(input);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading journal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _journalDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _journalDate) {
      setState(() {
        _journalDate = picked;
      });
    }
  }

  void _addNewLine() {
    setState(() {
      _lineInputs.add(JournalLineInput());
    });
  }

  void _removeLine(int index) {
    if (_lineInputs.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A journal entry requires at least 2 lines.')),
      );
      return;
    }
    setState(() {
      final removed = _lineInputs.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(coaAccountsProvider);
    final coaList = accountsState.value ?? [];

    // Enforce lock verification
    final isLocked = ref.watch(transactionLockValidatorProvider).isLocked(
          module: TransactionLockModule.manualJournals,
          date: _journalDate,
        );

    // Calculate dynamic totals for real-time validation feedback
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final input in _lineInputs) {
      totalDebit += double.tryParse(input.debitController.text) ?? 0.0;
      totalCredit += double.tryParse(input.creditController.text) ?? 0.0;
    }
    final isBalanced = (totalDebit - totalCredit).abs() < 0.015;
    final hasUnsavedChanges = !_isSubmitted && (
      _journalNumberController.text.isNotEmpty ||
      _referenceNumberController.text.isNotEmpty ||
      _notesController.text.isNotEmpty
    );

    return UnsavedChangesWrapper(
      hasChanges: hasUnsavedChanges,
      child: ResponsiveScaffold(
        currentRoute: '/accounting/journals',
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Journal Entry' : 'New Journal Entry'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Warning banner if date falls in a locked period
                    LockWarningBanner(
                      module: TransactionLockModule.manualJournals,
                      date: _journalDate,
                    ),

                    Expanded(
                      child: ListView(
                        children: [
                          // Header Settings Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _journalNumberController,
                                          decoration: const InputDecoration(labelText: 'Journal Number *'),
                                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.m),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _referenceNumberController,
                                          decoration: const InputDecoration(labelText: 'Reference Number'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.s),
                                  TextFormField(
                                    controller: _notesController,
                                    decoration: const InputDecoration(labelText: 'Notes / Narration'),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Journal Date: ${DateFormat('yyyy-MM-dd').format(_journalDate)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.calendar_today, size: 16),
                                        label: const Text('Change Date'),
                                        onPressed: () => _selectDate(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Lines Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Journal Lines',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Line'),
                                onPressed: _addNewLine,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),

                          // Dynamic Lines Builder
                          ...List.generate(_lineInputs.length, (index) {
                            final input = _lineInputs[index];
                            return _buildLineItem(index, input, coaList);
                          }),
                        ],
                      ),
                    ),

                    // Validation Summary Bottom Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: Text(
                                  'Total Debit: ₹${totalDebit.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Total Credit: ₹${totalCredit.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (!isBalanced)
                            const Text(
                              'Out of Balance! Debits must equal Credits.',
                              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => context.pop(),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              ElevatedButton(
                                onPressed: isLocked || !isBalanced ? null : _handleSubmit,
                                child: const Text('Save Entry'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ));
  }

  Widget _buildLineItem(int index, JournalLineInput input, List<ChartOfAccount> coaList) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade300,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
                  onPressed: () => _removeLine(index),
                ),
              ],
            ),
            DropdownButtonFormField<int?>(
              initialValue: input.accountId,
              decoration: const InputDecoration(labelText: 'Account *'),
              items: coaList.map((ChartOfAccount a) {
                return DropdownMenuItem<int?>(
                  value: a.id,
                  child: Text('${a.accountName} (${a.accountCode ?? 'No Code'})'),
                );
              }).toList(),
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (val) {
                setState(() {
                  input.accountId = val;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: input.descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: input.debitController,
                    decoration: const InputDecoration(labelText: 'Debit (₹)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    onChanged: (v) {
                      if (v.isNotEmpty) {
                        input.creditController.clear(); // A line cannot have both debit and credit
                      }
                      setState(() {});
                    },
                    validator: (v) {
                      final hasDebit = v != null && v.isNotEmpty;
                      final hasCredit = input.creditController.text.isNotEmpty;
                      if (!hasDebit && !hasCredit) return 'Enter Debit OR Credit';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: TextFormField(
                    controller: input.creditController,
                    decoration: const InputDecoration(labelText: 'Credit (₹)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    onChanged: (v) {
                      if (v.isNotEmpty) {
                        input.debitController.clear(); // A line cannot have both debit and credit
                      }
                      setState(() {});
                    },
                    validator: (v) {
                      final hasCredit = v != null && v.isNotEmpty;
                      final hasDebit = input.debitController.text.isNotEmpty;
                      if (!hasDebit && !hasCredit) return 'Enter Debit OR Credit';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final lines = _lineInputs.map((input) {
        return JournalLine(
          id: 0,
          journalEntryId: widget.journalId ?? 0,
          accountId: input.accountId!,
          description: input.descriptionController.text.trim().isEmpty ? null : input.descriptionController.text.trim(),
          debit: double.tryParse(input.debitController.text) ?? 0.0,
          credit: double.tryParse(input.creditController.text) ?? 0.0,
        );
      }).toList();

      double totalDebit = 0.0;
      double totalCredit = 0.0;
      for (final line in lines) {
        totalDebit += line.debit;
        totalCredit += line.credit;
      }

      final journal = JournalEntry(
        id: widget.journalId ?? 0,
        userId: 0,
        journalNumber: _journalNumberController.text,
        journalDate: _journalDate,
        referenceNumber: _referenceNumberController.text.trim().isEmpty ? null : _referenceNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        status: 'published',
        isDeleted: false,
        lines: lines,
      );

      try {
        if (_isEditMode) {
          await ref.read(journalsProvider.notifier).updateJournal(widget.journalId!, journal);
        } else {
          await ref.read(journalsProvider.notifier).createJournal(journal);
        }

        if (mounted) {
          setState(() => _isSubmitted = true);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Journal entry saved successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving journal: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
