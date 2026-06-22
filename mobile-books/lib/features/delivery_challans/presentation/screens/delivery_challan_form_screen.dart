import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan_item.dart';
import 'package:mobile_books/features/delivery_challans/presentation/providers/delivery_challan_provider.dart';
import 'package:mobile_books/features/delivery_challans/data/services/delivery_challan_service.dart';

class _LineItem {
  int? itemId;
  String itemName;
  String description;
  double quantity;
  String unit;
  double rate;

  _LineItem({
    this.itemId,
    this.itemName = '',
    this.description = '',
    this.quantity = 1,
    this.unit = '',
    this.rate = 0,
  });
}

class DeliveryChallanFormScreen extends ConsumerStatefulWidget {
  final int? challanId;
  final int? convertFromSalesOrderId;

  const DeliveryChallanFormScreen({super.key, this.challanId, this.convertFromSalesOrderId});

  @override
  ConsumerState<DeliveryChallanFormScreen> createState() => _DeliveryChallanFormScreenState();
}

class _DeliveryChallanFormScreenState extends ConsumerState<DeliveryChallanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInit = false;

  int? _customerId;
  DateTime _challanDate = DateTime.now();
  DateTime? _deliveryDate;
  final _addressController = TextEditingController();
  final _refController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  List<_LineItem> _lineItems = [_LineItem()];

  bool get _isEditMode => widget.challanId != null;

  @override
  void dispose() {
    _addressController.dispose();
    _refController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && _isEditMode) {
      _loadChallanData();
    }
  }

  Future<void> _loadChallanData() async {
    setState(() => _isLoading = true);
    try {
      final details = await ref.read(deliveryChallanServiceProvider).getDeliveryChallanById(widget.challanId!);
      final dc = details.deliveryChallan;
      _customerId = dc.customerId;
      _challanDate = dc.challanDate;
      _deliveryDate = dc.deliveryDate;
      _addressController.text = dc.deliveryAddress ?? '';
      _refController.text = dc.referenceNumber ?? '';
      _notesController.text = dc.notes ?? '';
      _termsController.text = dc.termsConditions ?? '';

      if (details.items.isNotEmpty) {
        _lineItems = details.items
            .map((i) => _LineItem(
                  itemId: i.itemId,
                  itemName: i.itemName,
                  description: i.description ?? '',
                  quantity: i.quantity,
                  unit: i.unit ?? '',
                  rate: i.rate,
                ))
            .toList();
      }
      _isInit = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load challan: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChallan() async {
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

    final dcItems = _lineItems.map((li) {
      return DeliveryChallanItem(
        itemId: li.itemId,
        itemName: li.itemName,
        description: li.description,
        quantity: li.quantity,
        unit: li.unit,
        rate: li.rate,
        lineTotal: li.quantity * li.rate,
      );
    }).toList();

    final dc = DeliveryChallan(
      id: widget.challanId ?? 0,
      userId: 0,
      customerId: _customerId,
      salesOrderId: widget.convertFromSalesOrderId,
      deliveryChallanNumber: '',
      challanDate: _challanDate,
      deliveryDate: _deliveryDate,
      deliveryAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      referenceNumber: _refController.text.trim().isEmpty ? null : _refController.text.trim(),
      status: 'Draft',
      stockReduced: false,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      termsConditions: _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
    );

    try {
      if (_isEditMode) {
        final Map<String, dynamic> updates = dc.toJson();
        updates['items'] = dcItems.map((i) => i.toJson()).toList();
        await ref.read(deliveryChallansProvider.notifier).updateDeliveryChallan(widget.challanId!, updates);
      } else {
        await ref.read(deliveryChallansProvider.notifier).createDeliveryChallan(dc, dcItems);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Delivery Challan updated successfully.' : 'Delivery Challan issued successfully.')),
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
        title: Text(_isEditMode ? 'Edit Delivery Challan' : 'New Delivery Challan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveChallan,
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
                                  _addressController.text = cust.billingAddress ?? '';
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
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _challanDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _challanDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Challan Date *',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormat('dd MMM yyyy').format(_challanDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _deliveryDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _deliveryDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expected Delivery Date',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(_deliveryDate != null ? DateFormat('dd MMM yyyy').format(_deliveryDate!) : 'Select Date'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(labelText: 'Reference Number'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Delivery Address', hintText: 'Address to ship goods to...'),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items To Ship', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              error: (e, s) => Text('Error loading products: $e'),
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
                                      li.unit = selected.unit ?? 'pcs';
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
                                    initialValue: li.unit,
                                    decoration: const InputDecoration(labelText: 'Unit'),
                                    onChanged: (val) {
                                      li.unit = val;
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
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes', hintText: 'Internal description...'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _termsController,
                    decoration: const InputDecoration(labelText: 'Terms & Conditions'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveChallan,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Save Delivery Challan'),
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
        _addressController.text = result.billingAddress ?? '';
      });
    }
  }
}
