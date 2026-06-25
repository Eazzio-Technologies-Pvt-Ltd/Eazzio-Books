import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/widgets/searchable_autocomplete_field.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';
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
  final _amountReceivedController = TextEditingController();
  final _bankChargesController = TextEditingController(text: '0');
  final _refController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentNumberController = TextEditingController(text: 'Auto-generated');
  final _depositToController = TextEditingController(text: 'Petty Cash');

  int? _selectedCustomerId;
  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'Cash';
  String _taxDeducted = 'No Tax';
  bool _isLoading = false;

  // Map of invoice ID to payment amount allocated
  Map<int, double> paymentsMap = {};
  // Map of invoice ID to payment date
  Map<int, String> paymentDatesMap = {};

  bool _initialized = false;

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _bankChargesController.dispose();
    _refController.dispose();
    _notesController.dispose();
    _paymentNumberController.dispose();
    _depositToController.dispose();
    super.dispose();
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
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

  Future<void> _selectInvoicePaymentDate(BuildContext context, int invId) async {
    final initialDate = paymentDatesMap[invId] != null
        ? DateFormat('yyyy-MM-dd').parse(paymentDatesMap[invId]!)
        : _paymentDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        paymentDatesMap[invId] = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _handleAmountReceivedChanged(String val, List<dynamic> customerInvoices) {
    final double totalAmt = double.tryParse(val) ?? 0.0;
    double remaining = totalAmt;
    final newMap = <int, double>{};
    for (final inv in customerInvoices) {
      if (remaining <= 0) break;
      final due = inv.balanceDue;
      if (remaining >= due) {
        newMap[inv.id] = due;
        remaining -= due;
      } else {
        newMap[inv.id] = remaining;
        remaining = 0;
      }
    }
    setState(() {
      paymentsMap = newMap;
    });
  }

  void _onPaymentMapChanged(int invId, String val) {
    final double amt = double.tryParse(val) ?? 0.0;
    setState(() {
      if (amt <= 0) {
        paymentsMap.remove(invId);
      } else {
        paymentsMap[invId] = amt;
      }
      final double total = paymentsMap.values.fold(0.0, (sum, v) => sum + v);
      _amountReceivedController.text = total > 0 ? total.toStringAsFixed(2) : '';
    });
  }

  void _payInFull(dynamic inv) {
    setState(() {
      paymentsMap[inv.id] = inv.balanceDue;
      final double total = paymentsMap.values.fold(0.0, (sum, v) => sum + v);
      _amountReceivedController.text = total > 0 ? total.toStringAsFixed(2) : '';
    });
  }

  void _clearAppliedAmounts() {
    setState(() {
      paymentsMap.clear();
      _amountReceivedController.clear();
    });
  }

  Future<void> _save(String status) async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    final double amountUsed = paymentsMap.values.fold(0.0, (sum, v) => sum + v);
    if (amountUsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please apply an amount to at least one invoice')),
      );
      return;
    }

    final double totalReceived = double.tryParse(_amountReceivedController.text) ?? 0.0;
    if (amountUsed > totalReceived + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount applied exceeds Amount Received')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Loop through all invoices that have a payment allocation > 0 and call recordPayment
      for (final entry in paymentsMap.entries) {
        final amt = entry.value;
        if (amt > 0) {
          final invId = entry.key;
          final date = paymentDatesMap[invId] ?? DateFormat('yyyy-MM-dd').format(_paymentDate);
          
          await ref.read(invoicesProvider.notifier).recordPayment(invId, {
            'customer_id': _selectedCustomerId,
            'amount': amt,
            'payment_date': date,
            'payment_mode': _paymentMode,
            'reference': _refController.text.trim().isEmpty ? null : _refController.text.trim(),
            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            'status': status,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment(s) recorded successfully as ${status.toUpperCase()}.')),
        );
        ref.invalidate(paymentsProvider);
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

    final customersState = ref.watch(customersProvider);
    final invoicesState = ref.watch(invoicesProvider);

    ref.listen<AsyncValue<List<Invoice>>>(invoicesProvider, (previous, next) {
      if (next.hasValue && next.value != null && _selectedCustomerId != null) {
        final customerInvoices = next.value!.where((i) {
          return i.customerId == _selectedCustomerId &&
              i.balanceDue > 0 &&
              i.status.toLowerCase() != 'draft' &&
              i.status.toLowerCase() != 'cancelled';
        }).toList();
        customerInvoices.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
        if (_amountReceivedController.text.isNotEmpty && paymentsMap.isEmpty) {
          _handleAmountReceivedChanged(_amountReceivedController.text, customerInvoices);
        }
      }
    });

    final customers = customersState.value ?? [];
    final allInvoices = invoicesState.value ?? [];

    if (!_initialized && widget.invoiceId != 0 && allInvoices.isNotEmpty) {
      final invoice = allInvoices.where((i) => i.id == widget.invoiceId).firstOrNull;
      if (invoice != null) {
        _selectedCustomerId = invoice.customerId;
        paymentsMap[widget.invoiceId] = widget.balanceDue;
        _amountReceivedController.text = widget.balanceDue.toStringAsFixed(2);
        _initialized = true;
      }
    }

    // Filter active invoices with balance due for the selected customer
    final customerInvoices = allInvoices.where((i) {
      return i.customerId == _selectedCustomerId &&
          i.balanceDue > 0 &&
          i.status.toLowerCase() != 'draft' &&
          i.status.toLowerCase() != 'cancelled';
    }).toList();

    // Sort by date oldest first
    customerInvoices.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));

    final double amountUsed = paymentsMap.values.fold(0.0, (sum, v) => sum + v);
    final double amountReceivedVal = double.tryParse(_amountReceivedController.text) ?? 0.0;
    final double amountExcess = amountReceivedVal - amountUsed;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                  const SizedBox(height: AppSpacing.s),

                  SearchableAutocompleteField<Customer>(
                    initialValue: customers.where((c) => c.id == _selectedCustomerId).firstOrNull,
                    labelText: 'Customer Name *',
                    items: customers,
                    itemLabelBuilder: (c) => c.displayName ?? c.email ?? 'Customer #${c.id}',
                    searchMatcher: (c, query) {
                      final name = (c.displayName ?? '').toLowerCase();
                      final email = (c.email ?? '').toLowerCase();
                      final q = query.toLowerCase();
                      return name.contains(q) || email.contains(q);
                    },
                    onChanged: (val) {
                      setState(() {
                        _selectedCustomerId = val?.id;
                        paymentsMap.clear();
                        paymentDatesMap.clear();
                        _amountReceivedController.clear();
                      });
                    },
                    validator: (val) => val == null ? 'Customer is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Amount Received ───
                  TextFormField(
                    controller: _amountReceivedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount Received *',
                      prefixText: '₹ ',
                    ),
                    onChanged: (val) => _handleAmountReceivedChanged(val, customerInvoices),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Amount is required';
                      if (double.tryParse(val) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Bank Charges ───
                  TextFormField(
                    controller: _bankChargesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Bank Charges (if any)',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Payment Date ───
                  InkWell(
                    onTap: () => _selectPaymentDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Payment Date *',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Payment Number (Auto-generated) ───
                  TextFormField(
                    controller: _paymentNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Payment #',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Payment Mode ───
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
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

                  // ─── Deposit To / Account ───
                  TextFormField(
                    controller: _depositToController,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Reference ───
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'Reference',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Tax Deducted ChoiceChips ───
                  const Text('Tax Deducted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('No Tax'),
                        selected: _taxDeducted == 'No Tax',
                        onSelected: (selected) {
                          if (selected) setState(() => _taxDeducted = 'No Tax');
                        },
                      ),
                      const SizedBox(width: AppSpacing.s),
                      ChoiceChip(
                        label: const Text('TDS'),
                        selected: _taxDeducted == 'TDS',
                        onSelected: (selected) {
                          if (selected) setState(() => _taxDeducted = 'TDS');
                        },
                      ),
                      const SizedBox(width: AppSpacing.s),
                      ChoiceChip(
                        label: const Text('TCS'),
                        selected: _taxDeducted == 'TCS',
                        onSelected: (selected) {
                          if (selected) setState(() => _taxDeducted = 'TCS');
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // ─── Unpaid Invoices Section ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Unpaid Invoices',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (amountUsed > 0)
                        TextButton(
                          onPressed: _clearAppliedAmounts,
                          child: const Text('Clear Applied Amount'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),

                  if (_selectedCustomerId == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Please select a customer to view unpaid invoices',
                          style: TextStyle(color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else if (customerInvoices.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No unpaid invoices found for this customer',
                          style: TextStyle(color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: customerInvoices.length,
                      itemBuilder: (context, idx) {
                        final inv = customerInvoices[idx];
                        final invDateStr = DateFormat('dd/MM/yyyy').format(inv.invoiceDate);
                        final dueDateStr = DateFormat('dd/MM/yyyy').format(inv.dueDate ?? inv.invoiceDate);
                        final currentAllocated = paymentsMap[inv.id] ?? 0.0;
                        final controller = TextEditingController(
                          text: currentAllocated > 0 ? currentAllocated.toStringAsFixed(2) : '',
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      inv.invoiceNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                    ),
                                    TextButton(
                                      onPressed: () => _payInFull(inv),
                                      child: const Text('Pay in Full'),
                                    ),
                                  ],
                                ),
                                Text('Date: $invDateStr | Due: $dueDateStr', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Due Amount: ₹${inv.balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: AppSpacing.m),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectInvoicePaymentDate(context, inv.id),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Payment Date',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          child: Text(
                                            paymentDatesMap[inv.id] ?? DateFormat('yyyy-MM-dd').format(_paymentDate),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        controller: controller,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          hintText: '0.00',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        onChanged: (val) => _onPaymentMapChanged(inv.id, val),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const Divider(height: 32),

                  // ─── Totals summary card ───
                  Card(
                    color: AppColors.textSecondaryLight.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount Received:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('₹ ${amountReceivedVal.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount allocated for Payments:', style: TextStyle(color: AppColors.textSecondaryLight)),
                              Text('₹ ${amountUsed.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount Refunded:', style: TextStyle(color: AppColors.textSecondaryLight)),
                              const Text('₹ 0.00'),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                                  SizedBox(width: 4),
                                  Text('Amount in Excess:', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text('₹ ${amountExcess > 0 ? amountExcess.toStringAsFixed(2) : '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.m),

                  // ─── Notes ───
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Internal use. Not visible to customer)',
                      hintText: 'Internal details...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // ─── Two Action Buttons ───
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLocked ? null : () => _save('draft'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save as Draft'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLocked ? null : () => _save('paid'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save as Paid'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
    );
  }
}

