import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class PaymentReceivedFormScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  final double balanceDue;

  const PaymentReceivedFormScreen({
    super.key,
    required this.invoiceId,
    required this.balanceDue,
  });

  @override
  ConsumerState<PaymentReceivedFormScreen> createState() => _PaymentReceivedFormScreenState();
}

class _PaymentReceivedFormScreenState extends ConsumerState<PaymentReceivedFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.balanceDue.toStringAsFixed(2);
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
    if (!_formKey.currentState!.validate()) return;

    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount must be greater than zero.')),
      );
      return;
    }
    if (amt > widget.balanceDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment amount exceeds remaining balance due (₹${widget.balanceDue.toStringAsFixed(2)}).')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = {
        'amount': amt,
        'payment_date': DateFormat('yyyy-MM-dd').format(_paymentDate),
        'payment_mode': _paymentMode,
        'reference': _refController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      await ref.read(invoicesProvider.notifier).recordPayment(widget.invoiceId, payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully.')),
        );
        ref.invalidate(paymentsProvider); // Refresh the payments list provider
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
          module: TransactionLockModule.paymentsReceived,
          date: _paymentDate,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  LockWarningBanner(
                    module: TransactionLockModule.paymentsReceived,
                    date: _paymentDate,
                  ),
                  Text(
                    'Record payment against Invoice #${widget.invoiceId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Balance Due: ₹${widget.balanceDue.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.m),
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
