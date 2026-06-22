import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/utils/gst_calculator.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/features/credit_notes/data/models/credit_note.dart';
import 'package:mobile_books/features/credit_notes/data/models/credit_note_item.dart';
import 'package:mobile_books/features/credit_notes/presentation/providers/credit_note_provider.dart';
import 'package:mobile_books/features/credit_notes/data/services/credit_note_service.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class _LineItem {
  int? itemId;
  String itemName;
  String description;
  double quantity;
  double rate;
  double discount;
  String discountType; // 'flat' or 'percent'
  double taxRate;

  _LineItem({
    this.itemId,
    this.itemName = '',
    this.description = '',
    this.quantity = 1,
    this.rate = 0,
    this.discount = 0,
    this.discountType = 'flat',
    this.taxRate = 0,
  });
}

class CreditNoteFormScreen extends ConsumerStatefulWidget {
  final int? creditNoteId;

  const CreditNoteFormScreen({super.key, this.creditNoteId});

  @override
  ConsumerState<CreditNoteFormScreen> createState() => _CreditNoteFormScreenState();
}

class _CreditNoteFormScreenState extends ConsumerState<CreditNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInit = false;

  int? _customerId;
  DateTime _creditNoteDate = DateTime.now();
  final _refController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String get _supplierState => ref.watch(organizationSettingsProvider).value?.state ?? 'Jharkhand';
  String _placeOfSupply = 'Jharkhand';

  List<_LineItem> _lineItems = [_LineItem()];

  bool get _isEditMode => widget.creditNoteId != null;

  @override
  void dispose() {
    _refController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && _isEditMode) {
      _loadCreditNoteData();
    }
  }

  Future<void> _loadCreditNoteData() async {
    setState(() => _isLoading = true);
    try {
      final details = await ref.read(creditNoteServiceProvider).getCreditNoteById(widget.creditNoteId!);
      final cn = details.creditNote;
      _customerId = cn.customerId;
      _creditNoteDate = cn.creditNoteDate;
      _refController.text = cn.referenceNumber ?? '';
      _reasonController.text = cn.reason ?? '';
      _notesController.text = cn.notes ?? '';
      _termsController.text = cn.termsConditions ?? '';

      if (details.items.isNotEmpty) {
        _lineItems = details.items
            .map((i) => _LineItem(
                  itemId: i.itemId,
                  itemName: i.itemName,
                  description: i.description ?? '',
                  quantity: i.quantity,
                  rate: i.rate,
                  discount: i.discount,
                  discountType: i.discountType,
                  taxRate: i.taxRate,
                ))
            .toList();
      }
      _isInit = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load credit note: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  GstCalculatorResult get _calculations {
    final list = _lineItems.map((li) {
      return GstLineItem(
        quantity: li.quantity,
        unitPrice: li.rate,
        taxRate: li.taxRate,
        discount: li.discount,
        discountType: li.discountType,
      );
    }).toList();

    return GstCalculator.calculate(
      stateA: _supplierState,
      stateB: _placeOfSupply,
      items: list,
    );
  }

  Future<void> _saveCreditNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_lineItems.isEmpty || _lineItems.any((i) => i.itemId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid item for all line items.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    final calc = _calculations;
    final cnItems = _lineItems.map((li) {
      final lineCalc = GstCalculator.calculate(
        stateA: _supplierState,
        stateB: _placeOfSupply,
        items: [
          GstLineItem(
            quantity: li.quantity,
            unitPrice: li.rate,
            taxRate: li.taxRate,
            discount: li.discount,
            discountType: li.discountType,
          )
        ],
      );

      return CreditNoteItem(
        itemId: li.itemId,
        itemName: li.itemName,
        description: li.description,
        quantity: li.quantity,
        rate: li.rate,
        discount: li.discount,
        discountType: li.discountType,
        taxRate: li.taxRate,
        taxAmount: lineCalc.totalTax,
        lineTotal: lineCalc.totalAmount,
      );
    }).toList();

    final cn = CreditNote(
      id: widget.creditNoteId ?? 0,
      userId: 0,
      customerId: _customerId,
      creditNoteNumber: '',
      creditNoteDate: _creditNoteDate,
      referenceNumber: _refController.text.trim().isEmpty ? null : _refController.text.trim(),
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      status: 'Open',
      subtotal: calc.subtotal,
      discountTotal: calc.discountAmount,
      taxTotal: calc.totalTax,
      total: calc.totalAmount,
      appliedAmount: 0.0,
      remainingAmount: calc.totalAmount,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      termsConditions: _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
    );

    try {
      if (_isEditMode) {
        final Map<String, dynamic> updates = cn.toJson();
        updates['items'] = cnItems.map((i) => i.toJson()).toList();
        await ref.read(creditNotesProvider.notifier).updateCreditNote(widget.creditNoteId!, updates);
      } else {
        await ref.read(creditNotesProvider.notifier).createCreditNote(cn, cnItems);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Credit Note updated successfully.' : 'Credit Note issued successfully.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);
    final itemsState = ref.watch(itemsProvider);

    final isLocked = ref.watch(transactionLockValidatorProvider).isLocked(
          module: TransactionLockModule.creditNotes,
          date: _creditNoteDate,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Credit Note' : 'New Credit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: (_isLoading || isLocked) ? null : _saveCreditNote,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  LockWarningBanner(
                    module: TransactionLockModule.creditNotes,
                    date: _creditNoteDate,
                  ),
                  // Customer selection
                  customersState.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error loading customers: $e'),
                    data: (customers) => Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _customerId,
                            decoration: const InputDecoration(labelText: 'Customer *'),
                            isExpanded: true,
                            items: customers.map((c) {
                              final name = c.displayName ?? '${c.firstName ?? ""} ${c.lastName ?? ""}'.trim();
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(name.isEmpty ? (c.email ?? 'Customer #${c.id}') : name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _customerId = val;
                                if (val != null) {
                                  final cust = customers.firstWhere((c) => c.id == val);
                                  _placeOfSupply = cust.billingState ?? 'Jharkhand';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        IconButton(
                          onPressed: _showAddCustomerDialog,
                          icon: const Icon(Icons.person_add, color: AppColors.primaryBlue),
                          tooltip: 'Add Customer',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _creditNoteDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _creditNoteDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Credit Note Date *',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_creditNoteDate)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(labelText: 'Reference Number'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(labelText: 'Reason for Credit Note', hintText: 'e.g. Returned goods, Price offset...'),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primaryBlue),
                        onPressed: () {
                          setState(() {
                            _lineItems.add(_LineItem());
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  // Line Items builders
                  ..._lineItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final li = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        child: Column(
                          children: [
                            itemsState.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, s) => Text('Error items: $e'),
                              data: (items) => DropdownButtonFormField<int>(
                                initialValue: li.itemId,
                                decoration: InputDecoration(labelText: 'Select Item ${idx + 1}'),
                                items: items.map((item) {
                                  return DropdownMenuItem<int>(
                                    value: item.id,
                                    child: Text(item.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    li.itemId = val;
                                    if (val != null) {
                                      final selected = items.firstWhere((i) => i.id == val);
                                      li.itemName = selected.name;
                                      li.rate = selected.sellingPrice;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: li.quantity.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Quantity'),
                                    onChanged: (val) {
                                      li.quantity = double.tryParse(val) ?? 0.0;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: li.rate.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(labelText: 'Rate'),
                                    onChanged: (val) {
                                      li.rate = double.tryParse(val) ?? 0.0;
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: li.discount.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Discount'),
                                    onChanged: (val) {
                                      li.discount = double.tryParse(val) ?? 0.0;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: li.discountType,
                                  items: const [
                                    DropdownMenuItem(value: 'flat', child: Text('₹ (Flat)')),
                                    DropdownMenuItem(value: 'percent', child: Text('% (Percent)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        li.discountType = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: li.taxRate.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'GST %'),
                                    onChanged: (val) {
                                      li.taxRate = double.tryParse(val) ?? 0.0;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.danger),
                                  onPressed: () {
                                    setState(() {
                                      _lineItems.removeAt(idx);
                                      if (_lineItems.isEmpty) _lineItems.add(_LineItem());
                                    });
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(),
                  // Running total calc output block
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal: ₹${_calculations.subtotal.toStringAsFixed(2)}'),
                        Text('Discount: ₹${_calculations.discountAmount.toStringAsFixed(2)}'),
                        Text('GST Tax: ₹${_calculations.totalTax.toStringAsFixed(2)}'),
                        Text(
                          'Total Credit: ₹${_calculations.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes', hintText: 'Internal details...'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _termsController,
                    decoration: const InputDecoration(labelText: 'Terms & Conditions'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveCreditNote,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Save Credit Note'),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Inline Add Customer Dialog ────────────────────────────
  Future<void> _showAddCustomerDialog() async {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final result = await showDialog<Customer>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
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
                final customer = Customer(
                  id: 0,
                  customerType: 'Business',
                  displayName: nameCtrl.text.trim(),
                  companyName: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  currency: 'INR',
                  openingBalance: 0.0,
                  enablePortal: false,
                  portalLanguage: 'en',
                  isActive: true,
                  organizationId: 0,
                );
                final created = await ref
                    .read(customersProvider.notifier)
                    .createCustomer(customer);
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
        _customerId = result.id;
        _placeOfSupply = result.billingState ?? 'Jharkhand';
      });
    }
  }
}
