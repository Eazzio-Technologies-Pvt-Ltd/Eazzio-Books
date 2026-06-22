import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/utils/gst_calculator.dart';
import 'package:mobile_books/core/widgets/state_dropdown_field.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit_item.dart';
import 'package:mobile_books/features/vendor_credits/presentation/providers/vendor_credit_provider.dart';
import 'package:mobile_books/features/vendors/data/models/vendor.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class VendorCreditFormScreen extends ConsumerStatefulWidget {
  final int? vendorCreditId;

  const VendorCreditFormScreen({super.key, this.vendorCreditId});

  @override
  ConsumerState<VendorCreditFormScreen> createState() => _VendorCreditFormScreenState();
}

class _LineItem {
  int? itemId;
  String itemName = '';
  String? description;
  double quantity = 1.0;
  double rate = 0.0;
  double discount = 0.0;
  String discountType = 'flat';
  double taxRate = 0.0;

  double get lineTotal {
    double gross = quantity * rate;
    double discAmt = discountType == 'percent' ? gross * (discount / 100) : discount;
    double taxable = gross - discAmt;
    return taxable + (taxable * (taxRate / 100));
  }
}

class _VendorCreditFormScreenState extends ConsumerState<VendorCreditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  int? _vendorId;
  final _creditNumberController = TextEditingController();
  final _refController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();
  DateTime _creditDate = DateTime.now();

  String _vendorState = 'Jharkhand';
  String get _buyerState => ref.watch(organizationSettingsProvider).value?.state ?? 'Jharkhand';

  final List<_LineItem> _lineItems = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.vendorCreditId != null;
    if (_isEdit) {
      _loadVendorCreditData();
    } else {
      _lineItems.add(_LineItem());
    }
  }

  Future<void> _loadVendorCreditData() async {
    setState(() => _isLoading = true);
    try {
      final details = await ref.read(vendorCreditDetailsProvider(widget.vendorCreditId!).future);
      final vc = details.vendorCredit;
      _vendorId = vc.vendorId;
      _creditNumberController.text = vc.vendorCreditNumber;
      _refController.text = vc.referenceNumber ?? '';
      _reasonController.text = vc.reason ?? '';
      _notesController.text = vc.notes ?? '';
      _termsController.text = vc.termsConditions ?? '';
      _creditDate = vc.vendorCreditDate;

      // Suggest state from vendor's address if possible
      if (_vendorId != null) {
        final vendors = await ref.read(vendorsProvider.future);
        final vendor = vendors.firstWhere((v) => v.id == _vendorId);
        _vendorState = _suggestState(vendor.billingAddress) ?? 'Jharkhand';
      }

      _lineItems.clear();
      for (final item in details.items) {
        _lineItems.add(_LineItem()
          ..itemId = item.itemId
          ..itemName = item.itemName
          ..description = item.description
          ..quantity = item.quantity
          ..rate = item.rate
          ..discount = item.discount
          ..discountType = item.discountType
          ..taxRate = item.taxRate);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading Vendor Credit: $e'), backgroundColor: AppColors.danger),
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

  @override
  void dispose() {
    _creditNumberController.dispose();
    _refController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
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
    final vcItems = _lineItems.map((li) {
      final lineCalc = GstCalculator.calculate(
        stateA: _vendorState,
        stateB: _buyerState,
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

      return VendorCreditItem(
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

    final vc = VendorCredit(
      id: widget.vendorCreditId ?? 0,
      userId: 0,
      vendorId: _vendorId,
      vendorCreditNumber: _creditNumberController.text.trim(),
      vendorCreditDate: _creditDate,
      referenceNumber: _refController.text.trim().isEmpty ? null : _refController.text.trim(),
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      status: _isEdit ? 'Open' : 'Draft',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      termsConditions: _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
      subtotal: calc.subtotal,
      discountTotal: calc.discountAmount,
      taxTotal: calc.totalTax,
      total: calc.totalAmount,
      appliedAmount: 0.0,
      remainingAmount: calc.totalAmount,
    );

    try {
      if (_isEdit) {
        await ref.read(vendorCreditsProvider.notifier).updateVendorCredit(
          widget.vendorCreditId!,
          {
            ...vc.toJson(),
            'items': vcItems.map((i) => i.toJson()).toList(),
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor Credit updated successfully.')),
        );
      } else {
        await ref.read(vendorCreditsProvider.notifier).createVendorCredit(vc, vcItems);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor Credit created successfully.')),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving Vendor Credit: $e'), backgroundColor: AppColors.danger),
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
          module: TransactionLockModule.vendorCredits,
          date: _creditDate,
        );

    if (_isLoading && _isEdit) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit Vendor Credit' : 'New Vendor Credit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Vendor Credit' : 'New Vendor Credit'),
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
                  module: TransactionLockModule.vendorCredits,
                  date: _creditDate,
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
                          decoration: const InputDecoration(labelText: 'Vendor *'),
                          isExpanded: true,
                          items: vendors.map((v) {
                            return DropdownMenuItem<int>(
                              value: v.id,
                              child: Text(v.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _vendorId = val;
                              if (val != null) {
                                final vendor = vendors.firstWhere((v) => v.id == val);
                                final suggested = _suggestState(vendor.billingAddress);
                                if (suggested != null) {
                                  _vendorState = suggested;
                                }
                              }
                            });
                          },
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

                // Vendor Credit Details
                TextFormField(
                  controller: _creditNumberController,
                  decoration: const InputDecoration(labelText: 'Vendor Credit #', hintText: 'Leave blank to auto-generate'),
                ),
                const SizedBox(height: AppSpacing.m),

                // Vendor State manual select dropdown
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

                // Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _creditDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _creditDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Vendor Credit Date'),
                    child: Text(DateFormat('dd MMM yyyy').format(_creditDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Reference & Reason
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _refController,
                        decoration: const InputDecoration(labelText: 'Reference #'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(labelText: 'Reason'),
                      ),
                    ),
                  ],
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
                    margin: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      child: Column(
                        children: [
                          itemsState.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) => Text('Error: $e'),
                            data: (items) => DropdownButtonFormField<int>(
                              initialValue: li.itemId,
                              decoration: InputDecoration(labelText: 'Item ${idx + 1} *'),
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
                                    li.rate = selected.costPrice; // Purchase-side uses costPrice
                                    li.taxRate = selected.taxRate;
                                    li.description = selected.purchaseDescription ?? selected.description;
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
                                  key: Key('rate_${li.itemId}_${li.rate}'),
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
                              Expanded(
                                child: TextFormField(
                                  key: Key('tax_${li.itemId}_${li.taxRate}'),
                                  initialValue: li.taxRate.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Tax %'),
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
                              icon: const Icon(Icons.delete, color: AppColors.danger),
                              onPressed: () {
                                setState(() {
                                  _lineItems.removeAt(idx);
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
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _termsController,
                  decoration: const InputDecoration(labelText: 'Terms & Conditions'),
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
      setState(() {
        _vendorId = result.id;
        final suggested = _suggestState(result.billingAddress);
        if (suggested != null) {
          _vendorState = suggested;
        }
      });
    }
  }
}
