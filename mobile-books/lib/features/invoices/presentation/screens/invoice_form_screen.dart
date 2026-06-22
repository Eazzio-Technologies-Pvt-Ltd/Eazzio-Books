import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/utils/gst_calculator.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/items/data/models/item.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/invoices/data/models/invoice_item.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/quotes/data/services/quote_service.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart'; // Reusing salesperson and project providers
import 'package:mobile_books/features/invoices/data/services/invoice_service.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/quotes/data/models/salesperson.dart';
import 'package:mobile_books/features/quotes/data/models/project.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

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

  double getTaxAmount(String gstType) {
    return afterDiscount * (taxRate / 100);
  }

  double getLineTotal(String gstType) {
    return afterDiscount + getTaxAmount(gstType);
  }
}

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final int? invoiceId;
  final int? convertFromQuoteId;

  const InvoiceFormScreen({
    super.key,
    this.invoiceId,
    this.convertFromQuoteId,
  });

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isInit = false;

  // ─── Header Fields ─────────────────────────────────────────
  int? _customerId;
  String _invoiceNumber = '';
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  int? _salespersonId;
  int? _projectId;
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  // ─── GST Fields ────────────────────────────────────────────
  String _supplierState = 'Jharkhand';
  String _placeOfSupply = 'Jharkhand';
  String _customerGstin = '';
  String _gstType = 'intra_state';

  // ─── Line Items ────────────────────────────────────────────
  List<_LineItem> _lineItems = [_LineItem()];

  bool get _isEditMode => widget.invoiceId != null;
  bool get _isConversion => widget.convertFromQuoteId != null;

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      if (_isEditMode) {
        _loadInvoiceData();
      } else if (_isConversion) {
        _loadQuoteForConversion();
      }
    }
  }

  Future<void> _loadInvoiceData() async {
    setState(() => _isLoading = true);
    try {
      final details =
          await ref.read(invoiceServiceProvider).getInvoiceById(widget.invoiceId!);
      final inv = details.invoice;
      _customerId = inv.customerId;
      _invoiceNumber = inv.invoiceNumber;
      _invoiceDate = inv.invoiceDate;
      _dueDate = inv.dueDate;
      _salespersonId = inv.salespersonId;
      _projectId = inv.projectId;
      _notesController.text = inv.notes ?? '';
      _termsController.text = inv.terms ?? '';
      _supplierState = inv.supplierState ?? 'Jharkhand';
      _placeOfSupply = inv.placeOfSupply ?? 'Jharkhand';
      _customerGstin = inv.customerGstin ?? '';
      _gstType = inv.gstType ?? 'intra_state';

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
              content: Text('Failed to load invoice: $e'),
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
              content: Text('Failed to pre-fill from quote: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Calculations ──────────────────────────────────────────
  GstCalculatorResult get _calculations {
    final gstItems = _lineItems.map((li) {
      return GstLineItem(
        quantity: li.quantity,
        unitPrice: li.unitPrice,
        taxRate: li.taxRate,
        discount: li.discount,
        discountType: li.discountType == 'percent' ? 'percentage' : 'flat',
      );
    }).toList();

    return GstCalculator.calculate(
      stateA: _supplierState,
      stateB: _placeOfSupply,
      items: gstItems,
    );
  }

  double get _subtotal => _calculations.subtotal;
  double get _totalDiscount => _calculations.discountAmount;
  double get _totalTax => _calculations.totalTax;
  double get _grandTotal => _calculations.totalAmount;

  void _updateGstType() {
    setState(() {
      if (_supplierState.trim().toLowerCase() == _placeOfSupply.trim().toLowerCase()) {
        _gstType = 'intra_state';
      } else {
        _gstType = 'inter_state';
      }
    });
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

  // ─── Inline Add Salesperson Dialog ─────────────────────────
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
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              try {
                final sp = await ref
                    .read(quoteServiceProvider)
                    .createSalesperson(
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
      ref.invalidate(salespersonsProvider);
      setState(() => _salespersonId = result.id);
    }
  }

  // ─── Inline Add Project Dialog ─────────────────────────────
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
                    backgroundColor: AppColors.warning,
                  ),
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
      ref.invalidate(projectsProvider);
      setState(() => _projectId = result.id);
    }
  }

  // ─── Save ──────────────────────────────────────────────────
  Future<void> _saveInvoice(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_lineItems.isEmpty || _lineItems.any((i) => i.itemId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a valid item for all line items.'),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    final List<InvoiceItem> items = _lineItems.map((li) {
      final taxableVal = li.afterDiscount;
      final itemCalc = GstCalculator.calculate(
        stateA: _supplierState,
        stateB: _placeOfSupply,
        items: [
          GstLineItem(
            quantity: li.quantity,
            unitPrice: li.unitPrice,
            taxRate: li.taxRate,
            discount: li.discount,
            discountType: li.discountType == 'percent' ? 'percentage' : 'flat',
          ),
        ],
      );

      return InvoiceItem(
        id: 0,
        invoiceId: widget.invoiceId ?? 0,
        itemId: li.itemId,
        itemName: li.itemName,
        hsnCode: li.hsnCode,
        unit: li.unit,
        description: li.description,
        quantity: li.quantity,
        unitPrice: li.unitPrice,
        taxRate: li.taxRate,
        discount: li.discount,
        discountType: li.discountType,
        total: itemCalc.totalAmount,
        taxableValue: taxableVal,
        cgstRate: itemCalc.isIntraState ? li.taxRate / 2 : 0.0,
        cgstAmount: itemCalc.cgstAmount,
        sgstRate: itemCalc.isIntraState ? li.taxRate / 2 : 0.0,
        sgstAmount: itemCalc.sgstAmount,
        igstRate: !itemCalc.isIntraState ? li.taxRate : 0.0,
        igstAmount: itemCalc.igstAmount,
      );
    }).toList();

    final invoice = Invoice(
      id: widget.invoiceId ?? 0,
      customerId: _customerId!,
      userId: 0,
      invoiceNumber: _invoiceNumber,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      status: status,
      notes: _notesController.text,
      terms: _termsController.text,
      totalAmount: _grandTotal,
      balanceDue: _grandTotal,
      salespersonId: _salespersonId,
      projectId: _projectId,
      quoteId: widget.convertFromQuoteId,
      supplierState: _supplierState,
      placeOfSupply: _placeOfSupply,
      customerGstin: _customerGstin,
      gstType: _gstType,
    );

    try {
      if (_isEditMode) {
        final Map<String, dynamic> updates = invoice.toJson();
        updates.remove('id');
        updates['items'] = items.map((i) {
          final m = i.toJson();
          m.remove('id');
          m.remove('invoice_id');
          return m;
        }).toList();

        await ref.read(invoicesProvider.notifier).updateInvoice(widget.invoiceId!, updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice updated successfully')),
          );
          context.pop();
        }
      } else {
        await ref.read(invoicesProvider.notifier).createInvoice(invoice, items);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice created successfully')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save invoice: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(organizationSettingsProvider).value;
    if (!_isInit && !_isEditMode && !_isConversion && orgSettings != null) {
      _supplierState = orgSettings.state ?? 'Jharkhand';
      _placeOfSupply = orgSettings.state ?? 'Jharkhand';
      _isInit = true;
    }

    final isLocked = ref.watch(transactionLockValidatorProvider).isLocked(
          module: TransactionLockModule.invoices,
          date: _invoiceDate,
        );

    final customersState = ref.watch(customersProvider);
    final itemsState = ref.watch(itemsProvider);
    final salespersonsState = ref.watch(salespersonsProvider);
    final projectsState = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Invoice' : 'New Invoice'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: isLocked ? null : () => _saveInvoice(_isEditMode ? 'sent' : 'draft'),
            ),
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
                    module: TransactionLockModule.invoices,
                    date: _invoiceDate,
                  ),
                  // ─── Customer Selection Card ────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer Info', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(height: AppSpacing.m),
                          customersState.when(
                            loading: () => const Text('Loading customers...'),
                            error: (err, stack) => Text('Error: $err'),
                            data: (list) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(labelText: 'Customer *'),
                                      initialValue: _customerId,
                                      items: list.map((c) {
                                        final name = c.displayName ?? '${c.firstName ?? ""} ${c.lastName ?? ""}'.trim();
                                        return DropdownMenuItem<int>(
                                          value: c.id,
                                          child: Text(name.isNotEmpty ? name : (c.email ?? '')),
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
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Header Info Card ───────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invoice Meta Details', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(height: AppSpacing.m),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Invoice Date'),
                            subtitle: Text(DateFormat('dd MMM yyyy').format(_invoiceDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _invoiceDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _invoiceDate = picked);
                              }
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Due Date'),
                            subtitle: Text(_dueDate == null
                                ? 'Due on receipt (No specific date)'
                                : DateFormat('dd MMM yyyy').format(_dueDate!)),
                            trailing: const Icon(Icons.calendar_today),
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
                          ),
                          salespersonsState.when(
                            loading: () => const Text('Loading salespeople...'),
                            error: (err, stack) => const Text('Error loading salespeople'),
                            data: (list) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(labelText: 'Salesperson'),
                                      initialValue: _salespersonId,
                                      items: [
                                        const DropdownMenuItem<int>(value: null, child: Text('None')),
                                        ...list.map((sp) => DropdownMenuItem<int>(
                                              value: sp.id,
                                              child: Text(sp.name),
                                            ))
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
                            },
                          ),
                          const SizedBox(height: AppSpacing.m),
                          projectsState.when(
                            loading: () => const Text('Loading projects...'),
                            error: (err, stack) => const Text('Error loading projects'),
                            data: (list) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(labelText: 'Project'),
                                      initialValue: _projectId,
                                      items: [
                                        const DropdownMenuItem<int>(value: null, child: Text('None')),
                                        ...list.map((p) => DropdownMenuItem<int>(
                                              value: p.id,
                                              child: Text(p.projectName),
                                            ))
                                      ],
                                      onChanged: (val) => setState(() => _projectId = val),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  IconButton(
                                    onPressed: _showAddProjectDialog,
                                    icon: const Icon(Icons.add_task, color: AppColors.primaryBlue),
                                    tooltip: 'Add Project',
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── GST Info Card ──────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GST & Place of Supply', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(height: AppSpacing.m),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Supplier State'),
                            controller: TextEditingController(text: _supplierState),
                            onChanged: (val) {
                              _supplierState = val;
                              _updateGstType();
                            },
                          ),
                          const SizedBox(height: AppSpacing.m),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Place of Supply'),
                            controller: TextEditingController(text: _placeOfSupply),
                            onChanged: (val) {
                              _placeOfSupply = val;
                              _updateGstType();
                            },
                          ),
                          const SizedBox(height: AppSpacing.m),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Customer GSTIN'),
                            controller: TextEditingController(text: _customerGstin),
                            onChanged: (val) => _customerGstin = val,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GST Type:'),
                              Text(
                                _gstType == 'intra_state' ? 'Intra-State (CGST + SGST)' : 'Inter-State (IGST)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Line Items Card ────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                                onPressed: () {
                                  setState(() {
                                    _lineItems.add(_LineItem());
                                  });
                                },
                              ),
                            ],
                          ),
                          const Divider(height: AppSpacing.m),
                          itemsState.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Text('Error loading items: $err'),
                            data: (itemList) {
                              return Column(
                                children: List.generate(_lineItems.length, (index) {
                                  final li = _lineItems[index];
                                  return _buildLineItemRow(index, li, itemList);
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ─── Totals and Notes Card ──────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(height: AppSpacing.m),
                          _summaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
                          _summaryRow('Discount', '₹${_totalDiscount.toStringAsFixed(2)}'),
                          _summaryRow('Taxes', '₹${_totalTax.toStringAsFixed(2)}'),
                          const Divider(),
                          _summaryRow('Grand Total', '₹${_grandTotal.toStringAsFixed(2)}', isBold: true),
                          const SizedBox(height: AppSpacing.m),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(labelText: 'Customer Notes'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          TextField(
                            controller: _termsController,
                            decoration: const InputDecoration(labelText: 'Terms & Conditions'),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildLineItemRow(int index, _LineItem li, List<Item> itemList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Item'),
                initialValue: li.itemId,
                items: itemList.map((i) {
                  return DropdownMenuItem<int>(
                    value: i.id,
                    child: Text(i.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final item = itemList.firstWhere((i) => i.id == val);
                    setState(() {
                      li.itemId = item.id;
                      li.itemName = item.name;
                      li.unitPrice = item.sellingPrice;
                      li.taxRate = item.taxRate;
                      li.hsnCode = item.hsnCode ?? '';
                      li.unit = item.unit ?? '';
                      li.description = item.description ?? '';
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              flex: 1,
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Qty'),
                keyboardType: TextInputType.number,
                initialValue: li.quantity.toString(),
                onChanged: (val) {
                  setState(() {
                    li.quantity = double.tryParse(val) ?? 1.0;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.danger),
              onPressed: () {
                setState(() {
                  _lineItems.removeAt(index);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Rate (₹)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: TextEditingController(text: li.unitPrice.toString())..selection = TextSelection.collapsed(offset: li.unitPrice.toString().length),
                onChanged: (val) {
                  setState(() {
                    li.unitPrice = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Discount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                initialValue: li.discount.toString(),
                onChanged: (val) {
                  setState(() {
                    li.discount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            DropdownButton<String>(
              value: li.discountType,
              items: const [
                DropdownMenuItem(value: 'flat', child: Text('₹')),
                DropdownMenuItem(value: 'percent', child: Text('%')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    li.discountType = val;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Line Total: ₹${li.getLineTotal(_gstType).toStringAsFixed(2)}  (Tax: ${li.taxRate}%)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
        ),
        const Divider(height: AppSpacing.l),
      ],
    );
  }

  Widget _summaryRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
