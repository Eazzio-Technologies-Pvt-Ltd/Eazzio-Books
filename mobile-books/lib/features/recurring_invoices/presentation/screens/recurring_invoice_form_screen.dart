import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/utils/gst_calculator.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice_item.dart';
import 'package:mobile_books/features/recurring_invoices/presentation/providers/recurring_invoice_provider.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';

class _LineItem {
  int? itemId;
  String itemName = '';
  String description = '';
  double quantity = 1;
  double rate = 0;
  double discount = 0;
  double taxRate = 0;

  _LineItem();
}

class RecurringInvoiceFormScreen extends ConsumerStatefulWidget {
  const RecurringInvoiceFormScreen({super.key});

  @override
  ConsumerState<RecurringInvoiceFormScreen> createState() => _RecurringInvoiceFormScreenState();
}

class _RecurringInvoiceFormScreenState extends ConsumerState<RecurringInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _profileNameController = TextEditingController();
  int? _customerId;
  String _frequency = 'Monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _autoSendEmail = false;

  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String get _supplierState => ref.watch(organizationSettingsProvider).value?.state ?? 'Jharkhand';
  String _placeOfSupply = 'Jharkhand';

  final List<_LineItem> _lineItems = [_LineItem()];

  @override
  void dispose() {
    _profileNameController.dispose();
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
        discountType: 'flat', // Default flat discounts per standard recurring layout
      );
    }).toList();

    return GstCalculator.calculate(
      stateA: _supplierState,
      stateB: _placeOfSupply,
      items: list,
    );
  }

  Future<void> _submit() async {
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
    final riItems = _lineItems.map((li) {
      final lineCalc = GstCalculator.calculate(
        stateA: _supplierState,
        stateB: _placeOfSupply,
        items: [
          GstLineItem(
            quantity: li.quantity,
            unitPrice: li.rate,
            taxRate: li.taxRate,
            discount: li.discount,
            discountType: 'flat',
          )
        ],
      );

      return RecurringInvoiceItem(
        itemId: li.itemId,
        itemName: li.itemName,
        description: li.description,
        quantity: li.quantity,
        rate: li.rate,
        discount: li.discount,
        taxRate: li.taxRate,
        taxAmount: lineCalc.totalTax,
        lineTotal: lineCalc.totalAmount,
      );
    }).toList();

    final ri = RecurringInvoice(
      id: 0,
      userId: 0,
      recurringInvoiceNumber: '',
      profileName: _profileNameController.text.trim(),
      customerId: _customerId!,
      frequency: _frequency,
      startDate: _startDate,
      endDate: _endDate,
      status: 'Active',
      subtotal: calc.subtotal,
      discountTotal: calc.discountAmount,
      taxTotal: calc.totalTax,
      total: calc.totalAmount,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      termsConditions: _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
      autoSendEmail: _autoSendEmail,
    );

    try {
      await ref.read(recurringInvoicesProvider.notifier).createRecurringInvoice(ri, riItems);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring Invoice Profile created successfully.')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Recurring Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _submit,
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
                  TextFormField(
                    controller: _profileNameController,
                    decoration: const InputDecoration(labelText: 'Profile Name *'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Profile name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  customersState.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
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
                  DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(labelText: 'Repeat Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                      DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _frequency = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _startDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date *',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _endDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date (Optional)',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'Never ends'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SwitchListTile(
                    title: const Text('Auto Send Invoice via Email'),
                    value: _autoSendEmail,
                    onChanged: (val) {
                      setState(() {
                        _autoSendEmail = val;
                      });
                    },
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
                                    decoration: const InputDecoration(labelText: 'Discount (Flat)'),
                                    onChanged: (val) {
                                      li.discount = double.tryParse(val) ?? 0.0;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: li.taxRate.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'GST Tax %'),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal: ₹${_calculations.subtotal.toStringAsFixed(2)}'),
                        Text('Discount: ₹${_calculations.discountAmount.toStringAsFixed(2)}'),
                        Text('GST Tax: ₹${_calculations.totalTax.toStringAsFixed(2)}'),
                        Text(
                          'Total Per Invoice: ₹${_calculations.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes', hintText: 'Auto-invoice description...'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _termsController,
                    decoration: const InputDecoration(labelText: 'Terms & Conditions'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Save Recurring Profile'),
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
