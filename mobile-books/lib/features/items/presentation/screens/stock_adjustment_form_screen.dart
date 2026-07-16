import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/items/data/models/item.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class StockAdjustmentFormScreen extends ConsumerStatefulWidget {
  const StockAdjustmentFormScreen({super.key});

  @override
  ConsumerState<StockAdjustmentFormScreen> createState() =>
      _StockAdjustmentFormScreenState();
}

class _StockAdjustmentFormScreenState
    extends ConsumerState<StockAdjustmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  int? _selectedItemId;
  String _movementType = 'stock_in'; // 'stock_in', 'stock_out', 'adjustment'
  final _quantityController = TextEditingController();
  final _referenceController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(List<Item> items) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an item')));
      return;
    }

    final selectedItem = items.firstWhere((i) => i.id == _selectedItemId);
    final qty = double.tryParse(_quantityController.text) ?? 0.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than zero')),
      );
      return;
    }

    if (_movementType == 'stock_out') {
      final currentStock = selectedItem.stockQuantity;
      if (qty > currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot dispatch $qty. Current stock is only $currentStock.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final body = {
        'item_id': _selectedItemId,
        'movement_type': _movementType,
        'quantity': qty,
        'reason': _reasonController.text.isNotEmpty
            ? _reasonController.text
            : null,
        'reference_number': _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      };

      await ref.read(itemsProvider.notifier).createInventoryMovement(body);
      ref.invalidate(allInventoryMovementsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory adjusted successfully')),
        );
        context.pushReplacement('/inventory/movements');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);

    return ResponsiveScaffold(
      currentRoute: '/inventory/stock',
      appBar: AppBar(
        title: const Text('New Inventory Adjustment'),
        leading: IconButton(
          icon: const Icon(AppIcons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          final physicalItems = items
              .where((i) => i.itemType.toLowerCase() != 'service')
              .toList();
          final selectedItem = _selectedItemId != null
              ? physicalItems.firstWhere(
                  (i) => i.id == _selectedItemId,
                  orElse: () => physicalItems.first,
                )
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                AppIcons.inventory_2_outlined,
                                color: AppColors.primaryBlue,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New Inventory Adjustment',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Adjust item quantities, record stock movements, or align current levels',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),

                          // Item dropdown
                          DropdownButtonFormField<int>(
                            initialValue: _selectedItemId,
                            decoration: const InputDecoration(
                              labelText: 'Item *',
                              hintText: 'Select an Item',
                            ),
                            items: physicalItems.map((item) {
                              return DropdownMenuItem<int>(
                                value: item.id,
                                child: Text(
                                  '${item.name} (SKU: ${item.sku ?? 'N/A'})',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedItemId = val;
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Item is required' : null,
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Dynamic Selected Item Information Card
                          if (selectedItem != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50.withAlpha(102),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        'Current Stock',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${selectedItem.stockQuantity} ${selectedItem.unit ?? 'pcs'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'Reorder Level',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${selectedItem.reorderLevel}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.m),
                          ],

                          // Movement Type selector
                          const Text(
                            'Movement Type *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: AppSpacing.s,
                            runSpacing: AppSpacing.s,
                            children: [
                              _buildMovementTypeButton(
                                label: 'Stock In',
                                icon: AppIcons.arrow_downward,
                                isSelected: _movementType == 'stock_in',
                                onTap: () =>
                                    setState(() => _movementType = 'stock_in'),
                              ),
                              _buildMovementTypeButton(
                                label: 'Stock Out',
                                icon: AppIcons.arrow_upward,
                                isSelected: _movementType == 'stock_out',
                                onTap: () =>
                                    setState(() => _movementType = 'stock_out'),
                              ),
                              _buildMovementTypeButton(
                                label: 'Adjustment',
                                icon: AppIcons.sync_alt,
                                isSelected: _movementType == 'adjustment',
                                onTap: () => setState(
                                  () => _movementType = 'adjustment',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Quantity input
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Quantity *',
                              hintText: 'e.g. 10',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Quantity is required';
                              }
                              final numVal = double.tryParse(val);
                              if (numVal == null || numVal <= 0) {
                                return 'Enter a valid number greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Reference number
                          TextFormField(
                            controller: _referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Reference Number',
                              hintText: 'e.g. ADJ-2026-001',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Reason
                          TextFormField(
                            controller: _reasonController,
                            decoration: const InputDecoration(
                              labelText: 'Reason for Adjustment',
                              hintText:
                                  'e.g. Received from Supplier, Damaged Stock, Inventory Audit, Sample Given',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes / Description',
                              hintText:
                                  'Provide additional details about this inventory movement...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),

                          // Action Buttons
                          OverflowBar(
                            alignment: MainAxisAlignment.end,
                            spacing: AppSpacing.s,
                            overflowSpacing: AppSpacing.s,
                            children: [
                              OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _submitForm(physicalItems),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.l,
                                    vertical: AppSpacing.m,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Save Adjustment'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMovementTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46, minWidth: 108),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
