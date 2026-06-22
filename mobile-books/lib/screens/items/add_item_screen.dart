import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/item_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final int? itemId;

  const AddItemScreen({super.key, this.itemId});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _hsnController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _unitController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _openingStockRateController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _itemType = 'Goods';
  double _taxRate = 18.0; // Default GST in India
  bool _isInventoryTracked = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _prepopulateFields();
    }
  }

  void _prepopulateFields() {
    final itemState = ref.read(itemProvider);
    final item = itemState.items.firstWhere(
      (element) => element.id == widget.itemId,
      orElse: () => throw Exception('Item not found'),
    );

    _nameController.text = item.name;
    _skuController.text = item.sku ?? '';
    _hsnController.text = item.hsnCode ?? '';
    _sellingPriceController.text = item.sellingPrice.toString();
    _costPriceController.text = item.costPrice.toString();
    _unitController.text = item.unit ?? '';
    _descriptionController.text = item.description ?? '';
    _itemType = item.itemType;
    _taxRate = item.taxRate;
    _isInventoryTracked = item.isInventoryTracked;

    if (_isInventoryTracked) {
      _openingStockController.text = item.openingStock.toString();
      _openingStockRateController.text = item.openingStockRate.toString();
      _reorderLevelController.text = item.reorderLevel.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _hsnController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _unitController.dispose();
    _openingStockController.dispose();
    _openingStockRateController.dispose();
    _reorderLevelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final itemData = {
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim(),
      'hsn_code': _hsnController.text.trim(),
      'item_type': _itemType,
      'tax_rate': _taxRate,
      'unit': _unitController.text.trim(),
      'selling_price': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'cost_price': double.tryParse(_costPriceController.text) ?? 0.0,
      'is_inventory_tracked': _isInventoryTracked,
      'description': _descriptionController.text.trim(),
    };

    if (_isInventoryTracked) {
      itemData['opening_stock'] = double.tryParse(_openingStockController.text) ?? 0.0;
      itemData['opening_stock_rate'] = double.tryParse(_openingStockRateController.text) ?? 0.0;
      itemData['reorder_level'] = double.tryParse(_reorderLevelController.text) ?? 0.0;
      itemData['inventory_account'] = 'Inventory Asset';
    }

    bool success;
    if (_isEditMode) {
      success = await ref.read(itemProvider.notifier).editItem(widget.itemId!, itemData);
    } else {
      success = await ref.read(itemProvider.notifier).addItem(itemData);
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Item updated successfully' : 'Item added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } else {
      setState(() => _isSubmitting = false);
      if (mounted) {
        final error = ref.read(itemProvider).errorMessage ?? 'An error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Item' : 'New Item',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormSection(
                  title: 'BASIC INFORMATION',
                  children: [
                    // Item Type selection (Goods / Service)
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Goods', style: AppTextStyles.bodyMedium),
                            value: 'Goods',
                            groupValue: _itemType,
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() => _itemType = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Service', style: AppTextStyles.bodyMedium),
                            value: 'Service',
                            groupValue: _itemType,
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() => _itemType = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Item Name *',
                      placeholder: 'e.g. Logitech Wireless Mouse',
                      controller: _nameController,
                      validator: (val) => AppValidators.validateRequired(val, 'Item name'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'SKU / Part Number',
                      placeholder: 'e.g. LOGI-M337',
                      controller: _skuController,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Unit Measurement',
                      placeholder: 'e.g. pcs, boxes, kgs',
                      controller: _unitController,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormSection(
                  title: 'PRICING & TAX DETAILS',
                  children: [
                    AppTextField(
                      label: 'Selling Price (₹) *',
                      placeholder: '0.00',
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      validator: (val) => AppValidators.validateDouble(val, 'Selling price'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Cost Price (₹) *',
                      placeholder: '0.00',
                      controller: _costPriceController,
                      keyboardType: TextInputType.number,
                      validator: (val) => AppValidators.validateDouble(val, 'Cost price'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'HSN Code',
                      placeholder: 'e.g. 84713010',
                      controller: _hsnController,
                    ),
                    const SizedBox(height: 16),
                    // Tax Rate select dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Rate (GST)',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _taxRate,
                              isExpanded: true,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              onChanged: (value) {
                                setState(() => _taxRate = value!);
                              },
                              items: const [
                                DropdownMenuItem(value: 0.0, child: Text('GST @ 0%')),
                                DropdownMenuItem(value: 5.0, child: Text('GST @ 5%')),
                                DropdownMenuItem(value: 12.0, child: Text('GST @ 12%')),
                                DropdownMenuItem(value: 18.0, child: Text('GST @ 18%')),
                                DropdownMenuItem(value: 28.0, child: Text('GST @ 28%')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Inventory Tracking Switch Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Track Inventory Stock',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Automatically track stock levels and values',
                      style: AppTextStyles.caption,
                    ),
                    value: _isInventoryTracked,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() => _isInventoryTracked = value);
                    },
                  ),
                ),
                if (_isInventoryTracked) ...[
                  const SizedBox(height: 16),
                  _buildFormSection(
                    title: 'STOCK PARAMETERS',
                    children: [
                      AppTextField(
                        label: 'Opening Stock Level *',
                        placeholder: '0',
                        controller: _openingStockController,
                        keyboardType: TextInputType.number,
                        validator: (val) => AppValidators.validateDouble(val, 'Opening stock'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Opening Stock Value Rate (₹) *',
                        placeholder: '0.00',
                        controller: _openingStockRateController,
                        keyboardType: TextInputType.number,
                        validator: (val) => AppValidators.validateDouble(val, 'Opening rate'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Reorder Point Level *',
                        placeholder: 'e.g. 5',
                        controller: _reorderLevelController,
                        keyboardType: TextInputType.number,
                        validator: (val) => AppValidators.validateDouble(val, 'Reorder level'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _buildFormSection(
                  title: 'ADDITIONAL REMARKS',
                  children: [
                    AppTextField(
                      label: 'Product Description',
                      placeholder: 'Add details or remarks for invoices...',
                      controller: _descriptionController,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: _isEditMode ? 'Update Product' : 'Save Product',
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  isLoading: _isSubmitting,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({required String title, required List<Widget> children}) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(height: 20, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}
