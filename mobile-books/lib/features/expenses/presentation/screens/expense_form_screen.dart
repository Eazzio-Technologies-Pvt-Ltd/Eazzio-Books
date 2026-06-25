import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/expenses/data/models/expense.dart';
import 'package:mobile_books/features/expenses/presentation/providers/expense_provider.dart';
import 'package:mobile_books/features/vendors/data/models/vendor.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final int? expenseId;

  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  int? _vendorId;
  String _category = 'Other Expenses';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _refController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  String _status = 'unpaid';

  final List<String> _categories = [
    'Other Expenses',
    'Meals and Entertainment',
    'Rent Expense',
    'Office Supplies',
    'Travel Expenses',
    'Advertising & Marketing',
    'Consulting & Professional Services',
    'Salaries & Wages',
  ];

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
      final expense = await ref.read(
        expenseDetailsProvider(widget.expenseId!).future,
      );
      _vendorId = expense.vendorId;
      _category = _categories.contains(expense.category)
          ? expense.category
          : 'Other Expenses';
      _amountController.text = expense.amount.toString();
      _descriptionController.text = expense.description ?? '';
      _refController.text = expense.reference ?? '';
      _attachmentUrlController.text = expense.attachmentUrl ?? '';
      _expenseDate = expense.expenseDate;
      _status = expense.status;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading expense: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _refController.dispose();
    _attachmentUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadReceipt() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo (Camera)'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Choose PDF / Document'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    String? filePath;
    String? fileName;

    try {
      if (source == 'camera' || source == 'gallery') {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (image != null) {
          filePath = image.path;
          fileName = image.name;
        }
      } else if (source == 'file') {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        );
        if (result != null && result.files.single.path != null) {
          filePath = result.files.single.path;
          fileName = result.files.single.name;
        }
      }

      if (filePath == null || fileName == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No receipt file selected.')),
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      final serverPath = await ref
          .read(expensesProvider.notifier)
          .uploadReceipt(filePath, fileName);

      setState(() {
        _attachmentUrlController.text = serverPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt file uploaded successfully.')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        String errMsg = 'Permission denied or picker error.';
        if (e.code == 'photo_access_denied' ||
            e.code == 'camera_access_denied') {
          errMsg =
              'Access denied. Please enable camera/storage permissions in settings.';
        } else if (e.message != null) {
          errMsg = e.message!;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final expense = Expense(
      id: widget.expenseId ?? 0,
      userId: 0,
      vendorId: _vendorId,
      category: _category,
      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
      expenseDate: _expenseDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      reference: _refController.text.trim().isEmpty
          ? null
          : _refController.text.trim(),
      attachmentUrl: _attachmentUrlController.text.trim().isEmpty
          ? null
          : _attachmentUrlController.text.trim(),
      status: _status,
    );

    try {
      if (_isEdit) {
        await ref
            .read(expensesProvider.notifier)
            .updateExpense(widget.expenseId!, expense.toJson());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated successfully.')),
        );
      } else {
        await ref.read(expensesProvider.notifier).createExpense(expense);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense recorded successfully.')),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving expense: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorsProvider);

    final isLocked = ref
        .watch(transactionLockValidatorProvider)
        .isLocked(module: TransactionLockModule.expenses, date: _expenseDate);

    if (_isLoading && _isEdit) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_isEdit ? 'Edit Expense' : 'Record Expense'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_isEdit ? 'Edit Expense' : 'Record Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: (_isLoading || isLocked) ? null : _save,
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
                LockWarningBanner(
                  module: TransactionLockModule.expenses,
                  date: _expenseDate,
                ),
                // Vendor Dropdown
                vendorsState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text('Error loading vendors: $e'),
                  data: (vendors) => Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _vendorId,
                          decoration: const InputDecoration(
                            labelText: 'Vendor',
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('No Vendor'),
                            ),
                            ...vendors.map(
                              (v) => DropdownMenuItem<int>(
                                value: v.id,
                                child: Text(v.displayName),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _vendorId = val);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      IconButton(
                        onPressed: _showAddVendorDialog,
                        icon: const Icon(
                          Icons.person_add,
                          color: AppColors.primaryBlue,
                        ),
                        tooltip: 'Add Vendor',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category *',
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem<String>(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _category = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Amount is required';
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expenseDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _expenseDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expense Date',
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_expenseDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Status
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _status = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                TextFormField(
                  controller: _refController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number',
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Receipt Upload Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _attachmentUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Attachment URL',
                          hintText: 'Upload or input document url',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickAndUploadReceipt,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Receipt'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // ─── Inline Add Vendor Dialog ────────────────────────────
  Future<void> _showAddVendorDialog() async {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final result = await showDialog<Vendor>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vendor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name *'),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
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
                    content: Text('Display Name is required'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              try {
                final vendor = Vendor(
                  id: 0,
                  userId: 0,
                  displayName: nameCtrl.text.trim(),
                  companyName: companyCtrl.text.trim().isEmpty
                      ? null
                      : companyCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty
                      ? null
                      : emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                  openingBalance: 0.0,
                  status: 'active',
                );
                final created = await ref
                    .read(vendorsProvider.notifier)
                    .createVendor(vendor);
                if (ctx.mounted) Navigator.pop(ctx, created);
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
        _vendorId = result.id;
      });
    }
  }
}
