import 'package:flutter/material.dart';
import 'package:mobile_books/core/widgets/searchable_autocomplete_field.dart';
import 'package:mobile_books/features/items/data/models/item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/utils/gst_calculator.dart';
import 'package:mobile_books/core/widgets/state_dropdown_field.dart';
import 'package:mobile_books/features/bills/data/models/bill.dart';
import 'package:mobile_books/features/bills/data/models/bill_item.dart';
import 'package:mobile_books/features/bills/presentation/providers/bill_provider.dart';
import 'package:mobile_books/features/vendors/data/models/vendor.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  final int? billId;

  const BillFormScreen({super.key, this.billId});

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _LineItem {
  int? itemId;
  String itemName = '';
  String? description;
  String? hsnCode;
  String? unit;
  double quantity = 1.0;
  double unitPrice = 0.0;
  double discount = 0.0;
  double taxRate = 0.0;

  // Stable controllers so fields don't reset on setState
  late final TextEditingController qtyController;
  late final TextEditingController priceController;
  late final TextEditingController discountController;
  late final TextEditingController taxController;

  _LineItem() {
    qtyController = TextEditingController(text: quantity.toString());
    priceController = TextEditingController(text: unitPrice.toString());
    discountController = TextEditingController(text: discount.toString());
    taxController = TextEditingController(text: taxRate.toString());
  }

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    discountController.dispose();
    taxController.dispose();
  }

  double get lineTotal {
    double gross = quantity * unitPrice;
    double taxable = gross - discount;
    return taxable + (taxable * (taxRate / 100));
  }
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  int? _vendorId;
  final _billNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _billDate = DateTime.now();
  DateTime? _dueDate;
  String _status = 'draft';

  String _vendorState = 'Jharkhand';
  String get _buyerState => ref.watch(organizationSettingsProvider).value?.state ?? 'Jharkhand';

  final List<_LineItem> _lineItems = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.billId != null;
    if (_isEdit) {
      _loadBillData();
    } else {
      _lineItems.add(_LineItem());
    }
  }

  Future<void> _loadBillData() async {
    setState(() => _isLoading = true);
    try {
      final details = await ref.read(billDetailsProvider(widget.billId!).future);
      final bill = details.bill;
      _vendorId = bill.vendorId;
      _billNumberController.text = bill.billNumber;
      _notesController.text = bill.notes ?? '';
      _billDate = bill.billDate;
      _dueDate = bill.dueDate;
      _status = bill.status;

      // Suggest state from vendor's address if possible
      if (_vendorId != null) {
        final vendors = await ref.read(vendorsProvider.future);
        final vendor = vendors.firstWhere((v) => v.id == _vendorId);
        _vendorState = _suggestState(vendor.billingAddress) ?? 'Jharkhand';
      }

      _lineItems.clear();
      for (final item in details.items) {
        final li = _LineItem()
          ..itemId = item.itemId
          ..itemName = item.itemName
          ..description = item.description
          ..hsnCode = item.hsnCode
          ..unit = item.unit
          ..quantity = item.quantity
          ..unitPrice = item.unitPrice
          ..discount = item.discount
          ..taxRate = item.taxRate;
        // Sync controllers with loaded values
        li.qtyController.text = item.quantity.toString();
        li.priceController.text = item.unitPrice.toString();
        li.discountController.text = item.discount.toString();
        li.taxController.text = item.taxRate.toString();
        _lineItems.add(li);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading Bill: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _suggestState(String? billingAddress) {
    if (billingAddress == null || billingAddress.isEmpty) return null;
    final lowerAddr = billingAddress.toLowerCase();
    for (final state in indianStates) {
      if (lowerAddr.contains(state.toLowerCase())) {
        return state;
      }
    }
    return null;
  }

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
                  companyName: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
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
      ref.invalidate(vendorsProvider);
      setState(() => _vendorId = result.id);
    }
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _notesController.dispose();
    for (final li in _lineItems) {
      li.dispose();
    }
    super.dispose();
  }

  GstCalculatorResult get _calculations {
    final list = _lineItems.map((li) {
      return GstLineItem(
        quantity: li.quantity,
        unitPrice: li.unitPrice,
        taxRate: li.taxRate,
        discount: li.discount,
        discountType: 'flat', // Bill defaults to flat discount values
      );
    }).toList();

    return GstCalculator.calculate(
      stateA: _vendorState,
      stateB: _buyerState,
      items: list,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor'), backgroundColor: AppColors.warning),
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
    final billItems = _lineItems.map((li) {
      final lineCalc = GstCalculator.calculate(
        stateA: _vendorState,
        stateB: _buyerState,
        items: [
          GstLineItem(
            quantity: li.quantity,
            unitPrice: li.unitPrice,
            taxRate: li.taxRate,
            discount: li.discount,
            discountType: 'flat',
          )
        ],
      );

      return BillItem(
        itemId: li.itemId,
        itemName: li.itemName,
        description: li.description,
        hsnCode: li.hsnCode,
        unit: li.unit,
        quantity: li.quantity,
        unitPrice: li.unitPrice,
        discount: li.discount,
        taxRate: li.taxRate,
        total: lineCalc.totalAmount,
      );
    }).toList();

    final bill = Bill(
      id: widget.billId ?? 0,
      userId: 0,
      vendorId: _vendorId!,
      billNumber: _billNumberController.text.trim(),
      billDate: _billDate,
      dueDate: _dueDate,
      subtotal: calc.subtotal,
      discountAmount: calc.discountAmount,
      taxAmount: calc.totalTax,
      adjustment: 0.0,
      totalAmount: calc.totalAmount,
      balanceDue: calc.totalAmount, // initial balance_due is same as total
      status: _status,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      if (_isEdit) {
        await ref.read(billsProvider.notifier).updateBill(
          widget.billId!,
          {
            ...bill.toJson(),
            'items': billItems.map((i) => i.toJson()).toList(),
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill updated successfully.')),
        );
      } else {
        await ref.read(billsProvider.notifier).createBill(bill, billItems);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully.')),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving Bill: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorsProvider);
    final itemsState = ref.watch(itemsProvider);
    final calc = _calculations;

    final isLocked = ref.watch(transactionLockValidatorProvider).isLocked(
          module: TransactionLockModule.bills,
          date: _billDate,
        );

    if (_isLoading && _isEdit) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit Bill' : 'New Bill')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Bill' : 'New Bill'),
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
                  module: TransactionLockModule.bills,
                  date: _billDate,
                ),
                // Vendor Dropdown
                vendorsState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text('Error loading vendors: $e'),
                  data: (vendors) => Row(
                    children: [
                      Expanded(
                        child: SearchableAutocompleteField<Vendor>(
                          labelText: 'Vendor *',
                          initialValue: vendors.where((v) => v.id == _vendorId).firstOrNull,
                          items: vendors,
                          itemLabelBuilder: (v) => v.displayName,
                          searchMatcher: (v, query) {
                            return v.displayName.toLowerCase().contains(query.toLowerCase()) ||
                                (v.email ?? '').toLowerCase().contains(query.toLowerCase());
                          },
                          onChanged: (val) {
                            setState(() {
                              _vendorId = val?.id;
                              if (val != null) {
                                final suggested = _suggestState(val.billingAddress);
                                if (suggested != null) {
                                  _vendorState = suggested;
                                }
                              }
                            });
                          },
                          validator: (val) => val == null ? 'Vendor is required' : null,
                          onAddNew: _showAddVendorDialog,
                          addNewLabel: 'Add New Vendor',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      IconButton(
                        onPressed: _showAddVendorDialog,
                        icon: const Icon(Icons.person_add, color: AppColors.primaryBlue),
                        tooltip: 'Add Vendor',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Bill Details
                TextFormField(
                  controller: _billNumberController,
                  decoration: const InputDecoration(labelText: 'Bill #', hintText: 'Leave blank to auto-generate'),
                ),
                const SizedBox(height: AppSpacing.m),

                // State handling
                StateDropdownField(
                  label: 'Vendor State *',
                  value: _vendorState,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _vendorState = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _billDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _billDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Bill Date'),
                          child: Text(DateFormat('dd MMM yyyy').format(_billDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Due Date'),
                          child: Text(_dueDate == null
                              ? 'Select Date'
                              : DateFormat('dd MMM yyyy').format(_dueDate!)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                // Status
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(value: 'void', child: Text('Void')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _status = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.l),

                // Line Items Header
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

                // Line Items list
                ..._lineItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final li = entry.value;

                  return Card(
                    key: ValueKey('bill_item_$idx'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      child: Column(
                        children: [
                          itemsState.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) => Text('Error: $e'),
                            data: (items) => SearchableAutocompleteField<Item>(
                              key: ValueKey(
                                  'bill_item_picker_${li.itemId ?? 'new'}_$idx'),
                              labelText: 'Item ${idx + 1} *',
                              initialValue:
                                  items.where((i) => i.id == li.itemId).firstOrNull,
                              items: items,
                              itemLabelBuilder: (i) => i.name,
                              searchMatcher: (i, query) {
                                return i.name
                                        .toLowerCase()
                                        .contains(query.toLowerCase()) ||
                                    (i.hsnCode ?? '')
                                        .toLowerCase()
                                        .contains(query.toLowerCase());
                              },
                              onChanged: (val) {
                                setState(() {
                                  li.itemId = val?.id;
                                  if (val != null) {
                                    li.itemName = val.name;
                                    li.unitPrice = val.costPrice;
                                    li.hsnCode = val.hsnCode;
                                    li.unit = val.unit;
                                    li.taxRate = val.taxRate;
                                    li.description =
                                        val.purchaseDescription ?? val.description;
                                    // Sync controllers
                                    li.priceController.text =
                                        val.costPrice.toStringAsFixed(2);
                                    li.taxController.text =
                                        val.taxRate.toStringAsFixed(2);
                                  } else {
                                    li.itemName = '';
                                    li.unitPrice = 0.0;
                                    li.hsnCode = null;
                                    li.unit = null;
                                    li.taxRate = 0.0;
                                    li.description = null;
                                    li.priceController.text = '0.0';
                                    li.taxController.text = '0.0';
                                  }
                                });
                              },
                              validator: (val) =>
                                  val == null ? 'Item is required' : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: li.qtyController,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Quantity'),
                                  onChanged: (val) {
                                    li.quantity = double.tryParse(val) ?? 0.0;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: li.priceController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  decoration:
                                      const InputDecoration(labelText: 'Unit Price'),
                                  onChanged: (val) {
                                    li.unitPrice = double.tryParse(val) ?? 0.0;
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
                                  controller: li.discountController,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Discount'),
                                  onChanged: (val) {
                                    li.discount = double.tryParse(val) ?? 0.0;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: li.taxController,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Tax %'),
                                  onChanged: (val) {
                                    li.taxRate = double.tryParse(val) ?? 0.0;
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.delete, color: AppColors.danger),
                              onPressed: () {
                                setState(() {
                                  final removed = _lineItems.removeAt(idx);
                                  removed.dispose();
                                });
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.m),

                // Calculations Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        _summaryRow('Subtotal', '₹${calc.subtotal.toStringAsFixed(2)}'),
                        _summaryRow('Discount Total', '₹${calc.discountAmount.toStringAsFixed(2)}'),
                        _summaryRow(
                          _vendorState.trim().toLowerCase() == _buyerState.trim().toLowerCase()
                              ? 'CGST (half) + SGST (half)'
                              : 'IGST',
                          '₹${calc.totalTax.toStringAsFixed(2)}',
                        ),
                        const Divider(height: AppSpacing.m),
                        _summaryRow('Grand Total', '₹${calc.totalAmount.toStringAsFixed(2)}', isTotal: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
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

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? AppColors.primaryBlue : AppColors.textPrimaryLight)),
        ],
      ),
    );
  }
}
