import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/items/data/models/item.dart';
import 'package:mobile_books/features/items/data/services/item_service.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final int? itemId;

  const ItemFormScreen({
    super.key,
    this.itemId,
  });

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final List<String> _units = [
    'pcs', 'kg', 'g', 'gm', 'ltr', 'ml', 'm', 'cm', 'mm',
    'box', 'pack', 'roll', 'set', 'nos', 'hour', 'day', 'month'
  ];

  final List<String> _salesAccountsList = [
    'Sales', 'General Income', 'Interest Income',
    'Late Fee Income', 'Other Charges', 'Shipping Charge'
  ];

  final List<String> _purchaseAccountsList = [
    'Cost of Goods Sold', 'Advertising And Marketing', 'Automobile Expense',
    'Bad Debt', 'Bank Fees and Charges', 'Consultant Expense',
    'Credit Card Charges', 'Depreciation And Amortisation',
    'IT and Internet Expenses', 'Office Supplies', 'Rent Expense',
    'Salaries and Employee Wages', 'Travel Expense', 'Uncategorized'
  ];

  final List<String> _inventoryAccounts = [
    'Inventory Asset'
  ];

  // Controllers and state variables
  bool _isLoading = false;
  bool _isInit = false;

  String _itemType = 'Goods';
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _hsnController = TextEditingController();
  String? _unit;
  final _taxRateController = TextEditingController(text: '0.0');
  String? _imageUrl;

  // Sales Section State
  bool _salesEnabled = true;
  final _sellingPriceController = TextEditingController(text: '0.0');
  String _salesAccount = 'Sales';
  final _salesDescController = TextEditingController();

  // Purchase Section State
  bool _purchaseEnabled = true;
  final _costPriceController = TextEditingController(text: '0.0');
  String _purchaseAccount = 'Cost of Goods Sold';
  int? _preferredVendorId;
  final _purchaseDescController = TextEditingController();

  // Inventory Section State
  bool _isInventoryTracked = false;
  String _inventoryAccount = 'Inventory Asset';
  final _openingStockController = TextEditingController(text: '0.0');
  final _openingStockRateController = TextEditingController(text: '0.0');
  final _reorderLevelController = TextEditingController(text: '0.0');

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _hsnController.dispose();
    _taxRateController.dispose();
    _sellingPriceController.dispose();
    _salesDescController.dispose();
    _costPriceController.dispose();
    _purchaseDescController.dispose();
    _openingStockController.dispose();
    _openingStockRateController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.itemId != null) {
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final item = await ref.read(itemServiceProvider).getItemById(widget.itemId!);
      _itemType = item.itemType;
      _nameController.text = item.name;
      _skuController.text = item.sku ?? '';
      _hsnController.text = item.hsnCode ?? '';
      _unit = item.unit;
      _taxRateController.text = item.taxRate.toString();
      _imageUrl = item.imageUrl;

      _sellingPriceController.text = item.sellingPrice.toString();
      _salesAccount = item.salesAccount ?? 'Sales';
      _salesDescController.text = item.description ?? '';
      if (!_salesAccountsList.contains(_salesAccount)) {
        _salesAccountsList.add(_salesAccount);
      }

      _costPriceController.text = item.costPrice.toString();
      _purchaseAccount = item.purchaseAccount ?? 'Cost of Goods Sold';
      _preferredVendorId = item.preferredVendorId;
      _purchaseDescController.text = item.purchaseDescription ?? '';
      if (!_purchaseAccountsList.contains(_purchaseAccount)) {
        _purchaseAccountsList.add(_purchaseAccount);
      }

      _isInventoryTracked = item.isInventoryTracked;
      _inventoryAccount = item.inventoryAccount ?? 'Inventory Asset';
      _openingStockController.text = item.openingStock.toString();
      _openingStockRateController.text = item.openingStockRate.toString();
      _reorderLevelController.text = item.reorderLevel.toString();

      _salesEnabled = item.sellingPrice > 0 || item.salesAccount != null;
      _purchaseEnabled = item.costPrice > 0 || item.purchaseAccount != null;

      _isInit = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load item details: $e'), backgroundColor: AppColors.danger),
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageUrl = image.name;
        });
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  Future<void> _showAddSalesAccountDialog() async {
    final controller = TextEditingController();
    final newAccount = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sales Account'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Account Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newAccount != null && newAccount.isNotEmpty) {
      setState(() {
        if (!_salesAccountsList.contains(newAccount)) {
          _salesAccountsList.add(newAccount);
        }
        _salesAccount = newAccount;
      });
    }
  }

  Future<void> _showAddPurchaseAccountDialog() async {
    final controller = TextEditingController();
    final newAccount = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Purchase Account'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Account Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newAccount != null && newAccount.isNotEmpty) {
      setState(() {
        if (!_purchaseAccountsList.contains(newAccount)) {
          _purchaseAccountsList.add(newAccount);
        }
        _purchaseAccount = newAccount;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    final hsnCode = _hsnController.text.trim();
    final taxRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
    
    final sellingPrice = _salesEnabled ? (double.tryParse(_sellingPriceController.text.trim()) ?? 0.0) : 0.0;
    final salesAccount = _salesEnabled ? _salesAccount : null;
    final salesDesc = _salesEnabled ? _salesDescController.text.trim() : '';

    final costPrice = _purchaseEnabled ? (double.tryParse(_costPriceController.text.trim()) ?? 0.0) : 0.0;
    final purchaseAccount = _purchaseEnabled ? _purchaseAccount : null;
    final purchaseDesc = _purchaseEnabled ? _purchaseDescController.text.trim() : '';
    final preferredVendorId = _purchaseEnabled ? _preferredVendorId : null;

    final openingStock = _isInventoryTracked ? (double.tryParse(_openingStockController.text.trim()) ?? 0.0) : 0.0;
    final openingStockRate = _isInventoryTracked ? (double.tryParse(_openingStockRateController.text.trim()) ?? 0.0) : 0.0;
    final reorderLevel = _isInventoryTracked ? (double.tryParse(_reorderLevelController.text.trim()) ?? 0.0) : 0.0;

    try {
      if (widget.itemId == null) {
        // Create Item
        final itemPayload = Item(
          id: 0,
          name: name,
          sku: sku.isEmpty ? null : sku,
          hsnCode: hsnCode.isEmpty ? null : hsnCode,
          taxRate: taxRate,
          itemType: _itemType,
          unit: _itemType == 'Goods' ? _unit : null,
          imageUrl: _imageUrl,
          sellingPrice: sellingPrice,
          salesAccount: salesAccount,
          costPrice: costPrice,
          purchaseAccount: purchaseAccount,
          description: salesDesc.isEmpty ? null : salesDesc,
          purchaseDescription: purchaseDesc.isEmpty ? null : purchaseDesc,
          preferredVendorId: preferredVendorId,
          isInventoryTracked: _isInventoryTracked,
          inventoryAccount: _isInventoryTracked ? _inventoryAccount : null,
          openingStock: _isInventoryTracked ? openingStock : 0.0,
          openingStockRate: _isInventoryTracked ? openingStockRate : 0.0,
          reorderLevel: _isInventoryTracked ? reorderLevel : 0.0,
          stockQuantity: _isInventoryTracked ? openingStock : 0.0,
          organizationId: 0, // Assigned by server
        );

        await ref.read(itemsProvider.notifier).createItem(itemPayload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item created successfully')),
          );
          context.pop();
        }
      } else {
        // Update Item
        final updates = <String, dynamic>{
          'name': name,
          'sku': sku.isEmpty ? null : sku,
          'hsn_code': hsnCode.isEmpty ? null : hsnCode,
          'tax_rate': taxRate,
          'item_type': _itemType,
          'unit': _itemType == 'Goods' ? _unit : null,
          'image_url': _imageUrl,
          'selling_price': sellingPrice,
          'sales_account': salesAccount,
          'description': salesDesc.isEmpty ? null : salesDesc,
          'cost_price': costPrice,
          'purchase_account': purchaseAccount,
          'purchase_description': purchaseDesc.isEmpty ? null : purchaseDesc,
          'preferred_vendor_id': preferredVendorId,
          'is_inventory_tracked': _isInventoryTracked,
          'inventory_account': _isInventoryTracked ? _inventoryAccount : null,
          'opening_stock': _isInventoryTracked ? openingStock : 0.0,
          'opening_stock_rate': _isInventoryTracked ? openingStockRate : 0.0,
          'reorder_level': _isInventoryTracked ? reorderLevel : 0.0,
        };

        await ref.read(itemsProvider.notifier).updateItem(widget.itemId!, updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
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
    final vendorsState = ref.watch(legacyVendorsRawProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'New Item' : 'Edit Item'),
      ),
      body: _isLoading && !(_isInit || widget.itemId == null)
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Type Segment
                    Row(
                      children: [
                        const Text(
                          'Type: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'Goods',
                                label: Text('Goods'),
                                icon: Icon(Icons.inventory),
                              ),
                              ButtonSegment(
                                value: 'Service',
                                label: Text('Service'),
                                icon: Icon(Icons.build_circle),
                              ),
                            ],
                            selected: {_itemType},
                            onSelectionChanged: (val) {
                              setState(() {
                                _itemType = val.first;
                                if (_itemType == 'Service') {
                                  _isInventoryTracked = false;
                                  _unit = null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Image selector dropzone mockup
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageUrl != null && _imageUrl!.isNotEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image, color: AppColors.primaryBlue),
                                      const SizedBox(width: AppSpacing.s),
                                      Expanded(
                                        child: Text(
                                          _imageUrl!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _imageUrl = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    'Drag image(s) here or Browse images',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Primary Information
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        hintText: 'e.g. Blue ink pen',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter item name';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),



                    if (_itemType == 'Goods') ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        hint: const Text('Select unit'),
                        items: _units
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _unit = val;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.s),
                    ],

                    TextFormField(
                      controller: _taxRateController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate (%)',
                        hintText: 'e.g. 18.0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          if (double.tryParse(val) == null) return 'Enter valid rate';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Sales Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sales Information',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                ),
                                Switch(
                                  value: _salesEnabled,
                                  onChanged: (val) {
                                    setState(() {
                                      _salesEnabled = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                            if (_salesEnabled) ...[
                              TextFormField(
                                controller: _sellingPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Selling Price (INR) *',
                                  prefixText: '₹ ',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (!_salesEnabled) return null;
                                  if (val == null || val.trim().isEmpty) return 'Enter selling price';
                                  if (double.tryParse(val) == null) return 'Enter valid price';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.s),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _salesAccount,
                                      decoration: const InputDecoration(labelText: 'Sales Account'),
                                      items: _salesAccountsList
                                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _salesAccount = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: AppColors.primaryBlue),
                                    onPressed: _showAddSalesAccountDialog,
                                    tooltip: 'Add Sales Account',
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s),
                              TextFormField(
                                controller: _salesDescController,
                                decoration: const InputDecoration(labelText: 'Sales Description'),
                                maxLines: 2,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Purchases Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Purchase Information',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                ),
                                Switch(
                                  value: _purchaseEnabled,
                                  onChanged: (val) {
                                    setState(() {
                                      _purchaseEnabled = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                            if (_purchaseEnabled) ...[
                              TextFormField(
                                controller: _costPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Purchase Price (INR) *',
                                  prefixText: '₹ ',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (!_purchaseEnabled) return null;
                                  if (val == null || val.trim().isEmpty) return 'Enter purchase price';
                                  if (double.tryParse(val) == null) return 'Enter valid price';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.s),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _purchaseAccount,
                                      decoration: const InputDecoration(labelText: 'Purchase Account'),
                                      items: _purchaseAccountsList
                                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _purchaseAccount = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: AppColors.primaryBlue),
                                    onPressed: _showAddPurchaseAccountDialog,
                                    tooltip: 'Add Purchase Account',
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s),
                              vendorsState.when(
                                data: (vendors) => DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: _preferredVendorId,
                                  decoration: const InputDecoration(labelText: 'Preferred Vendor'),
                                  hint: const Text('Select preferred vendor'),
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('None'),
                                    ),
                                    ...vendors.map((v) => DropdownMenuItem<int>(
                                          value: v['id'] as int,
                                          child: Text(v['name'] as String),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _preferredVendorId = val;
                                    });
                                  },
                                ),
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.s),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                error: (_, _) => const Text('Failed to load vendors list'),
                              ),
                              const SizedBox(height: AppSpacing.s),
                              TextFormField(
                                controller: _purchaseDescController,
                                decoration: const InputDecoration(labelText: 'Purchase Description'),
                                maxLines: 2,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Inventory Section (only visible/enabled for Goods type)
                    if (_itemType == 'Goods') ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Track Inventory',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                  ),
                                  Switch(
                                    value: _isInventoryTracked,
                                    onChanged: (val) {
                                      setState(() {
                                        _isInventoryTracked = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (_isInventoryTracked) ...[
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _inventoryAccount,
                                  decoration: const InputDecoration(labelText: 'Inventory Asset Account'),
                                  items: _inventoryAccounts
                                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _inventoryAccount = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.s),
                                TextFormField(
                                  controller: _openingStockController,
                                  decoration: const InputDecoration(
                                    labelText: 'Opening Stock Quantity',
                                  ),
                                  enabled: widget.itemId == null,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (_isInventoryTracked && (val == null || val.trim().isEmpty)) {
                                      return 'Enter opening stock';
                                    }
                                    if (val != null && val.trim().isNotEmpty) {
                                      if (double.tryParse(val) == null) return 'Enter valid quantity';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.s),
                                TextFormField(
                                  controller: _openingStockRateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Opening Stock Rate per unit (INR)',
                                  ),
                                  enabled: widget.itemId == null,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (_isInventoryTracked && (val == null || val.trim().isEmpty)) {
                                      return 'Enter opening stock rate';
                                    }
                                    if (val != null && val.trim().isNotEmpty) {
                                      if (double.tryParse(val) == null) return 'Enter valid rate';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.s),
                                TextFormField(
                                  controller: _reorderLevelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reorder Level',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (_isInventoryTracked && (val == null || val.trim().isEmpty)) {
                                      return 'Enter reorder level';
                                    }
                                    if (val != null && val.trim().isNotEmpty) {
                                      if (double.tryParse(val) == null) return 'Enter valid reorder level';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Save Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                ),
              ),
            ),
    );
  }
}
