import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/bills/presentation/providers/bill_provider.dart';
import 'package:mobile_books/features/bills/data/models/bill.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/features/vendors/data/models/vendor.dart';
import 'package:mobile_books/features/payments_made/data/models/payment_made.dart';
import 'package:mobile_books/features/payments_made/presentation/providers/payment_made_provider.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class PaymentMadeFormScreen extends ConsumerStatefulWidget {
  final int billId;
  final double balanceDue;

  const PaymentMadeFormScreen({
    super.key,
    required this.billId,
    required this.balanceDue,
  });

  @override
  ConsumerState<PaymentMadeFormScreen> createState() => _PaymentMadeFormScreenState();
}

class _PaymentMadeFormScreenState extends ConsumerState<PaymentMadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'cash';
  bool _isLoading = false;
  int? _vendorId;
  int? _selectedBillId;
  double _currentBalanceDue = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedBillId = widget.billId != 0 ? widget.billId : null;
    _currentBalanceDue = widget.billId != 0 ? widget.balanceDue : 0.0;
    _amountController.text = _currentBalanceDue > 0 ? _currentBalanceDue.toStringAsFixed(2) : '';
    if (_selectedBillId != null) {
      _loadBillDetails();
    }
  }

  Future<void> _loadBillDetails() async {
    if (_selectedBillId == null) return;
    try {
      final details = await ref.read(billDetailsProvider(_selectedBillId!).future);
      if (mounted) {
        setState(() {
          _vendorId = details.bill.vendorId;
        });
      }
    } catch (_) {
      // Quietly fall back
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedBillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bill to apply payment.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount must be greater than zero.')),
      );
      return;
    }
    if (amt > _currentBalanceDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment amount exceeds remaining balance due (₹${_currentBalanceDue.toStringAsFixed(2)}).')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pm = PaymentMade(
        id: 0,
        userId: 0,
        billId: _selectedBillId!,
        vendorId: _vendorId,
        amount: amt,
        paymentDate: _paymentDate,
        paymentMode: _paymentMode,
        referenceNumber: _refController.text.trim().isEmpty ? null : _refController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: 'paid',
      );

      await ref.read(paymentsMadeProvider.notifier).createPaymentMade(pm);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully.')),
        );
        ref.invalidate(billsProvider);
        ref.invalidate(billDetailsProvider(_selectedBillId!));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(transactionLockValidatorProvider).isLocked(
          module: TransactionLockModule.paymentsMade,
          date: _paymentDate,
        );

    final billsState = ref.watch(billsProvider);
    final vendorsState = ref.watch(vendorsProvider);

    final bills = billsState.value ?? [];
    final vendors = vendorsState.value ?? [];
    final vendorMap = {for (var v in vendors) v.id: v.displayName};

    // Filter active bills with outstanding balance due
    final unpaidBills = bills.where((b) {
      return b.balanceDue > 0 &&
          b.status.toLowerCase() != 'draft' &&
          b.status.toLowerCase() != 'void';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment Made'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  LockWarningBanner(
                    module: TransactionLockModule.paymentsMade,
                    date: _paymentDate,
                  ),
                  if (widget.billId == 0) ...[
                    DropdownButtonFormField<int>(
                      value: _selectedBillId,
                      decoration: const InputDecoration(
                        labelText: 'Select Bill to Pay *',
                        border: OutlineInputBorder(),
                      ),
                      items: unpaidBills.map((b) {
                        final vName = vendorMap[b.vendorId] ?? 'Vendor #${b.vendorId}';
                        return DropdownMenuItem<int>(
                          value: b.id,
                          child: Text('${b.billNumber} ($vName) - Due: ₹${b.balanceDue.toStringAsFixed(2)}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selectedBill = unpaidBills.firstWhere((b) => b.id == val);
                          setState(() {
                            _selectedBillId = val;
                            _vendorId = selectedBill.vendorId;
                            _currentBalanceDue = selectedBill.balanceDue;
                            _amountController.text = _currentBalanceDue.toStringAsFixed(2);
                          });
                        }
                      },
                      validator: (val) => val == null ? 'Bill selection is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ] else ...[
                    Text(
                      'Record payment against Bill #${widget.billId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Balance Due: ₹${_currentBalanceDue.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount *',
                      prefixText: '₹ ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      if (double.tryParse(val) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Payment Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'check', child: Text('Check')),
                      DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _paymentMode = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'Reference Number / Transaction ID',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Internal details...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: isLocked ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Payment'),
                  ),
                ],
              ),
            ),
    );
  }
}
