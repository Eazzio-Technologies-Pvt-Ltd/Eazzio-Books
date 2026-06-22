import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/items/data/models/item.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order_item.dart';
import 'package:mobile_books/features/sales_orders/data/services/sales_order_service.dart';
import 'package:mobile_books/features/sales_orders/presentation/providers/sales_order_provider.dart';
import 'package:mobile_books/features/quotes/data/models/salesperson.dart';
import 'package:mobile_books/features/quotes/data/models/project.dart';
import 'package:mobile_books/features/quotes/data/services/quote_service.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart';

class _LineItem {
  int? itemId;
  String itemName;
  String description;
  double quantity;
  double unitPrice;
  double taxRate;
  double discount;
  String discountType; // 'flat' or 'percent'
  String hsnCode;
  String unit;

  _LineItem({
    this.itemId,
    this.itemName = '',
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0,
    this.taxRate = 0,
    this.discount = 0,
    this.discountType = 'flat',
    this.hsnCode = '',
    this.unit = '',
  });

  double get lineBase => quantity * unitPrice;
  double get discountAmount =>
      discountType == 'percent' ? lineBase * (discount / 100) : discount;
  double get afterDiscount => lineBase - discountAmount;
  double get taxAmount => afterDiscount * (taxRate / 100);
  double get lineTotal => afterDiscount + taxAmount;
}

class SalesOrderFormScreen extends ConsumerStatefulWidget {
  final int? salesOrderId;
  final int? convertFromQuoteId;

  const SalesOrderFormScreen({
    super.key,
    this.salesOrderId,
    this.convertFromQuoteId,
  });

  @override
  ConsumerState<SalesOrderFormScreen> createState() => _SalesOrderFormScreenState();
}

class _SalesOrderFormScreenState extends ConsumerState<SalesOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isInit = false;

  // ─── Header fields ─────────────────────────────────────────
  int? _customerId;
  String _salesOrderNumber = '';
  DateTime _salesOrderDate = DateTime.now();
  DateTime? _expectedShipmentDate;
  int? _salespersonId;
  int? _projectId;
  final _referenceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  // ─── Line items ────────────────────────────────────────────
  List<_LineItem> _lineItems = [_LineItem()];

  bool get _isEditMode => widget.salesOrderId != null;
  bool get _isConversion => widget.convertFromQuoteId != null;

  @override
  void dispose() {
    _referenceNumberController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      if (_isEditMode) {
        _loadSalesOrderData();
      } else if (_isConversion) {
        _loadQuoteForConversion();
      }
    }
  }

  Future<void> _loadSalesOrderData() async {
    setState(() => _isLoading = true);
    try {
      final details =
          await ref.read(salesOrderServiceProvider).getSalesOrderById(widget.salesOrderId!);
      final order = details.salesOrder;
      _customerId = order.customerId;
      _salesOrderNumber = order.salesOrderNumber;
      _salesOrderDate = order.salesOrderDate;
      _expectedShipmentDate = order.expectedShipmentDate;
      _referenceNumberController.text = order.referenceNumber ?? '';
      _salespersonId = order.salespersonId;
      _projectId = order.projectId;
      _notesController.text = order.notes ?? '';
      _termsController.text = order.terms ?? '';

      if (details.items.isNotEmpty) {
        _lineItems = details.items
            .map((i) => _LineItem(
                  itemId: i.itemId,
                  itemName: i.itemName ?? '',
                  description: i.description ?? '',
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  taxRate: i.taxRate,
                  discount: i.discount,
                  discountType: i.discountType,
                  hsnCode: i.hsnCode ?? '',
                  unit: i.unit ?? '',
                ))
            .toList();
      }
      _isInit = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load sales order: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuoteForConversion() async {
    setState(() => _isLoading = true);
    try {
      final details =
          await ref.read(quoteServiceProvider).getQuoteById(widget.convertFromQuoteId!);
      final q = details.quote;
      _customerId = q.customerId;
      _salespersonId = q.salespersonId;
      _projectId = q.projectId;
      _notesController.text = q.notes ?? '';
      _termsController.text = q.terms ?? '';

      if (details.items.isNotEmpty) {
        _lineItems = details.items
            .map((i) => _LineItem(
                  itemId: i.itemId,
                  itemName: i.itemName ?? '',
                  description: i.description ?? '',
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  taxRate: i.taxRate,
                  discount: i.discount,
                  discountType: i.discountType,
                  hsnCode: i.hsnCode ?? '',
                  unit: i.unit ?? '',
                ))
            .toList();
      }
      _isInit = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load quote details: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Calculations ──────────────────────────────────────────
  double get _subtotal =>
      _lineItems.fold(0.0, (sum, item) => sum + item.lineBase);
  double get _totalDiscount =>
      _lineItems.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get _totalTax =>
      _lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get _grandTotal => _subtotal - _totalDiscount + _totalTax;

  // ─── Save ──────────────────────────────────────────────────
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_lineItems.isEmpty ||
        _lineItems.every((i) => i.itemName.isEmpty && i.itemId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one line item'),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        final updates = <String, dynamic>{
          'customer_id': _customerId,
          'sales_order_date': _salesOrderDate.toIso8601String().split('T')[0],
          'expected_shipment_date': _expectedShipmentDate?.toIso8601String().split('T')[0],
          'reference_number': _referenceNumberController.text.trim().isEmpty
              ? null
              : _referenceNumberController.text.trim(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'terms': _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
          'salesperson_id': _salespersonId,
          'project_id': _projectId,
          'items': _lineItems
              .map((i) => {
                    'item_id': i.itemId,
                    'item_name': i.itemName.isEmpty ? null : i.itemName,
                    'hsn_code': i.hsnCode.isEmpty ? null : i.hsnCode,
                    'unit': i.unit.isEmpty ? null : i.unit,
                    'description': i.description.isEmpty ? null : i.description,
                    'quantity': i.quantity,
                    'unit_price': i.unitPrice,
                    'tax_rate': i.taxRate,
                    'discount': i.discount,
                    'discount_type': i.discountType,
                  })
              .toList(),
        };
        await ref
            .read(salesOrdersProvider.notifier)
            .updateSalesOrder(widget.salesOrderId!, updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales order updated successfully')),
          );
          context.pop();
        }
      } else {
        final salesOrderPayload = SalesOrder(
          id: 0,
          customerId: _customerId!,
          userId: 0,
          salesOrderNumber: _salesOrderNumber,
          salesOrderDate: _salesOrderDate,
          expectedShipmentDate: _expectedShipmentDate,
          referenceNumber: _referenceNumberController.text.trim().isEmpty
              ? null
              : _referenceNumberController.text.trim(),
          status: 'draft',
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          terms: _termsController.text.trim().isEmpty
              ? null
              : _termsController.text.trim(),
          total: _grandTotal,
          salespersonId: _salespersonId,
          projectId: _projectId,
        );

        final itemsPayload = _lineItems
            .map((i) => SalesOrderItem(
                  id: 0,
                  salesOrderId: 0,
                  itemId: i.itemId,
                  itemName: i.itemName.isEmpty ? null : i.itemName,
                  hsnCode: i.hsnCode.isEmpty ? null : i.hsnCode,
                  unit: i.unit.isEmpty ? null : i.unit,
                  description: i.description.isEmpty ? null : i.description,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  taxRate: i.taxRate,
                  discount: i.discount,
                  discountType: i.discountType,
                  total: i.lineTotal,
                ))
            .toList();

        await ref
            .read(salesOrdersProvider.notifier)
            .createSalesOrder(salesOrderPayload, itemsPayload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales order created successfully')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      ref.invalidate(customersProvider);
      setState(() => _customerId = result.id);
    }
  }

  Future<void> _showAddSalespersonDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final empIdCtrl = TextEditingController();

    final result = await showDialog<Salesperson>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Salesperson'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
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
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: empIdCtrl,
                decoration: const InputDecoration(labelText: 'Employee ID'),
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
                      content: Text('Name is required'),
                      backgroundColor: AppColors.warning),
                );
                return;
              }
              try {
                final sp = await ref.read(quoteServiceProvider).createSalesperson(
                      nameCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      employeeId: empIdCtrl.text.trim().isEmpty ? null : empIdCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx, sp);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.danger),
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
      ref.invalidate(salespersonsProvider);
      setState(() => _salespersonId = result.id);
    }
  }

  Future<void> _showAddProjectDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<Project>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Project Name *'),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
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
                      content: Text('Project name is required'),
                      backgroundColor: AppColors.warning),
                );
                return;
              }
              try {
                final proj = await ref.read(quoteServiceProvider).createProject(
                      Project(
                        id: 0,
                        userId: 0,
                        customerId: _customerId,
                        projectName: nameCtrl.text.trim(),
                        budget: 0,
                        billingType: 'Fixed Cost',
                        hourlyRate: 0,
                        status: 'Active',
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx, proj);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.danger),
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
      ref.invalidate(projectsProvider);
      setState(() => _projectId = result.id);
    }
  }

  void _handleCatalogItemSelected(int lineIndex, Item catalogItem) {
    setState(() {
      final li = _lineItems[lineIndex];
      li.itemId = catalogItem.id;
      li.itemName = catalogItem.name;
      li.description = catalogItem.description ?? catalogItem.name;
      li.unitPrice = catalogItem.sellingPrice;
      li.taxRate = catalogItem.taxRate;
      li.hsnCode = catalogItem.hsnCode ?? '';
      li.unit = catalogItem.unit ?? '';
    });
  }

  Future<DateTime?> _pickDate(DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);
    final catalogItemsState = ref.watch(itemsProvider);
    final salespersonsState = ref.watch(salespersonsProvider);
    final projectsState = ref.watch(projectsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Sales Order' : 'New Sales Order'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveForm,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryBlue),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: _isLoading && !_isInit && _isEditMode
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Details', style: textTheme.titleMedium),
                            const Divider(),
                            const SizedBox(height: AppSpacing.s),
                            customersState.when(
                              data: (customers) => _buildCustomerDropdown(customers),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Error: $e',
                                  style: const TextStyle(color: AppColors.danger)),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            _buildDateField(
                              label: 'Sales Order Date *',
                              value: _salesOrderDate,
                              onPicked: (d) => setState(() => _salesOrderDate = d),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            _buildDateField(
                              label: 'Expected Shipment Date',
                              value: _expectedShipmentDate,
                              onPicked: (d) => setState(() => _expectedShipmentDate = d),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            TextFormField(
                              controller: _referenceNumberController,
                              decoration: const InputDecoration(labelText: 'Reference Number'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Assignment', style: textTheme.titleMedium),
                            const Divider(),
                            const SizedBox(height: AppSpacing.s),
                            salespersonsState.when(
                              data: (list) => _buildSalespersonDropdown(list),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            projectsState.when(
                              data: (list) => _buildProjectDropdown(list),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Line Items', style: textTheme.titleMedium),
                                TextButton.icon(
                                  onPressed: () => setState(() => _lineItems.add(_LineItem())),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Item'),
                                ),
                              ],
                            ),
                            const Divider(),
                            catalogItemsState.when(
                              data: (catalogItems) => Column(
                                children: [
                                  for (int i = 0; i < _lineItems.length; i++)
                                    _buildLineItemCard(i, catalogItems),
                                ],
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Summary', style: textTheme.titleMedium),
                            const Divider(),
                            const SizedBox(height: AppSpacing.s),
                            _summaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
                            _summaryRow(
                              'Total Discount',
                              '- ₹${_totalDiscount.toStringAsFixed(2)}',
                              valueColor: AppColors.danger,
                            ),
                            _summaryRow(
                              'Total Tax',
                              '+ ₹${_totalTax.toStringAsFixed(2)}',
                              valueColor: AppColors.success,
                            ),
                            const Divider(),
                            _summaryRow(
                              'Grand Total',
                              '₹${_grandTotal.toStringAsFixed(2)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notes & Terms', style: textTheme.titleMedium),
                            const Divider(),
                            const SizedBox(height: AppSpacing.s),
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Customer Notes',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            TextField(
                              controller: _termsController,
                              decoration: const InputDecoration(
                                labelText: 'Terms & Conditions',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isEditMode ? 'Update Sales Order' : 'Create Sales Order',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerDropdown(List<Customer> customers) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _customerId,
            decoration: const InputDecoration(labelText: 'Customer *'),
            isExpanded: true,
            items: customers.map((c) {
              final name = c.displayName ??
                  [c.firstName, c.lastName]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' ');
              return DropdownMenuItem(
                value: c.id,
                child: Text(name.isEmpty ? (c.email ?? 'Customer #${c.id}') : name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _customerId = val),
            validator: (val) => val == null ? 'Customer is required' : null,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        IconButton(
          onPressed: _showAddCustomerDialog,
          icon: const Icon(Icons.person_add, color: AppColors.primaryBlue),
          tooltip: 'Add Customer',
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    final displayText = value != null
        ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
        : 'Select date';

    return InkWell(
      onTap: () async {
        final picked = await _pickDate(value);
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(displayText),
      ),
    );
  }

  Widget _buildSalespersonDropdown(List<Salesperson> list) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _salespersonId,
            decoration: const InputDecoration(labelText: 'Salesperson'),
            isExpanded: true,
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('— None —'),
              ),
              ...list.map((sp) => DropdownMenuItem(
                    value: sp.id,
                    child: Text(sp.name),
                  )),
            ],
            onChanged: (val) => setState(() => _salespersonId = val),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        IconButton(
          onPressed: _showAddSalespersonDialog,
          icon: const Icon(Icons.person_add_alt_1, color: AppColors.primaryBlue),
          tooltip: 'Add Salesperson',
        ),
      ],
    );
  }

  Widget _buildProjectDropdown(List<Project> list) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _projectId,
            decoration: const InputDecoration(labelText: 'Project'),
            isExpanded: true,
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('— None —'),
              ),
              ...list.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.projectName),
                  )),
            ],
            onChanged: (val) => setState(() => _projectId = val),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        IconButton(
          onPressed: _showAddProjectDialog,
          icon: const Icon(Icons.create_new_folder, color: AppColors.primaryBlue),
          tooltip: 'Add Project',
        ),
      ],
    );
  }

  Widget _buildLineItemCard(int index, List<Item> catalogItems) {
    final li = _lineItems[index];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (_lineItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                    onPressed: () => setState(() => _lineItems.removeAt(index)),
                    tooltip: 'Remove Item',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            DropdownButtonFormField<int>(
              initialValue: li.itemId,
              decoration: const InputDecoration(labelText: 'Select from Catalog'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('— Custom Item —'),
                ),
                ...catalogItems.map((item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    )),
              ],
              onChanged: (val) {
                if (val != null) {
                  final catalogItem = catalogItems.firstWhere((c) => c.id == val);
                  _handleCatalogItemSelected(index, catalogItem);
                } else {
                  setState(() {
                    li.itemId = null;
                    li.itemName = '';
                    li.hsnCode = '';
                    li.unit = '';
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.s),
            TextFormField(
              controller: TextEditingController(text: li.itemName),
              decoration: const InputDecoration(labelText: 'Item Name'),
              onChanged: (val) => li.itemName = val,
            ),
            const SizedBox(height: AppSpacing.s),
            TextFormField(
              controller: TextEditingController(text: li.description),
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (val) => li.description = val,
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: li.quantity.toString()),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => setState(() => li.quantity = double.tryParse(val) ?? 0),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Required';
                      }
                      final n = double.tryParse(val);
                      if (n == null || n <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: li.unitPrice.toString()),
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => setState(() => li.unitPrice = double.tryParse(val) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: li.taxRate.toString()),
                    decoration: const InputDecoration(labelText: 'Tax Rate %'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => setState(() => li.taxRate = double.tryParse(val) ?? 0),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: li.hsnCode),
                    decoration: const InputDecoration(labelText: 'HSN Code'),
                    onChanged: (val) => li.hsnCode = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: TextEditingController(text: li.discount.toString()),
                    decoration: const InputDecoration(labelText: 'Discount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => setState(() => li.discount = double.tryParse(val) ?? 0),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: li.discountType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'flat', child: Text('Flat (₹)')),
                      DropdownMenuItem(value: 'percent', child: Text('Percent (%)')),
                    ],
                    onChanged: (val) => setState(() => li.discountType = val ?? 'flat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Line Total',
                    style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight),
                  ),
                  Text(
                    '₹${li.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? null : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
