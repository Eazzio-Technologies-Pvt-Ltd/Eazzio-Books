import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/items/data/models/item.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';

class ItemDetailScreen extends ConsumerWidget {
  final int itemId;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(itemsProvider.notifier).deleteItem(itemId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(itemDetailsProvider(itemId));

    return detailState.when(
      data: (item) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(item.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/items/$itemId/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
                Tab(text: 'Movements'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _OverviewTab(item: item),
              _HistoryTab(itemId: itemId),
              _MovementsTab(item: item),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Text(err.toString(), style: const TextStyle(color: AppColors.danger)),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Item item;

  const _OverviewTab({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary Information', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow('Item Name', item.name),
                  _infoRow('SKU', item.sku ?? '—'),
                  _infoRow('HSN Code', item.hsnCode ?? '—'),
                  _infoRow('Item Type', item.itemType),
                  _infoRow('Unit of Measure', item.unit ?? '—'),
                  _infoRow('Tax Rate', '${item.taxRate}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Pricing and accounts details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales & Purchases Details', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow('Selling Price', '₹${item.sellingPrice.toStringAsFixed(2)}'),
                  _infoRow('Sales Account', item.salesAccount ?? '—'),
                  _infoRow('Cost Price', '₹${item.costPrice.toStringAsFixed(2)}'),
                  _infoRow('Purchase Account', item.purchaseAccount ?? '—'),
                  _infoRow('Sales Description', item.description ?? '—'),
                  _infoRow('Purchase Description', item.purchaseDescription ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Inventory tracking details card (only if enabled)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Inventory Details', style: textTheme.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.xs / 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.isInventoryTracked
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.textSecondaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          item.isInventoryTracked ? 'TRACKED' : 'UNTRACKED',
                          style: TextStyle(
                            color: item.isInventoryTracked ? AppColors.success : AppColors.textSecondaryLight,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  if (item.isInventoryTracked) ...[
                    _infoRow('Current Stock Quantity', item.stockQuantity.toStringAsFixed(2)),
                    _infoRow('Reorder Level', item.reorderLevel.toStringAsFixed(2)),
                    _infoRow('Inventory Asset Account', item.inventoryAccount ?? '—'),
                    _infoRow('Opening Stock', item.openingStock.toStringAsFixed(2)),
                    _infoRow('Opening Stock Rate', '₹${item.openingStockRate.toStringAsFixed(2)}'),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                      child: Text(
                        'Inventory tracking is disabled for this item.',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  final int itemId;

  const _HistoryTab({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(itemHistoryProvider(itemId));

    return historyState.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No modification history recorded.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final dateStr = log.createdAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt!.toLocal())
                : '—';

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.s),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: log.action.toUpperCase() == 'CREATED'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Icon(
                    log.action.toUpperCase() == 'CREATED' ? Icons.add : Icons.edit,
                    color: log.action.toUpperCase() == 'CREATED'
                        ? AppColors.success
                        : AppColors.primaryBlue,
                  ),
                ),
                title: Text(log.description),
                subtitle: Text(
                  'By ${log.username ?? "Unknown"} • $dateStr',
                  style: const TextStyle(fontSize: 12.0),
                ),
                trailing: Text(
                  log.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Text(err.toString(), style: const TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }
}

class _MovementsTab extends ConsumerStatefulWidget {
  final Item item;

  const _MovementsTab({required this.item});

  @override
  ConsumerState<_MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends ConsumerState<_MovementsTab> {
  final _formKey = GlobalKey<FormState>();
  String _movementType = 'stock_in';
  double _quantity = 0.0;
  String _referenceNumber = '';
  String _notes = '';
  bool _submitting = false;

  void _showAdjustStockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust Inventory Stock'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _movementType,
                    decoration: const InputDecoration(labelText: 'Adjustment Type'),
                    items: const [
                      DropdownMenuItem(value: 'stock_in', child: Text('Stock In (Add)')),
                      DropdownMenuItem(value: 'stock_out', child: Text('Stock Out (Deduct)')),
                      DropdownMenuItem(value: 'adjustment', child: Text('Set Absolute Stock')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _movementType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: _movementType == 'adjustment' ? 'Target Stock Quantity' : 'Quantity',
                      hintText: 'e.g. 10',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter quantity';
                      final d = double.tryParse(val);
                      if (d == null) return 'Enter a valid number';
                      if (d <= 0) return 'Quantity must be greater than zero';
                      if (_movementType == 'stock_out' && d > widget.item.stockQuantity) {
                        return 'Cannot deduct more than current stock (${widget.item.stockQuantity.toStringAsFixed(0)})';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      if (val != null) {
                        _quantity = double.parse(val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Reference Number',
                      hintText: 'e.g. ADJ-001',
                    ),
                    onSaved: (val) {
                      _referenceNumber = val ?? '';
                    },
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes / Reason',
                      hintText: 'e.g. Damaged items or stock sync',
                    ),
                    onSaved: (val) {
                      _notes = val ?? '';
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        setDialogState(() {
                          _submitting = true;
                        });
                        try {
                          await ref.read(itemsProvider.notifier).createInventoryMovement({
                            'item_id': widget.item.id,
                            'movement_type': _movementType,
                            'quantity': _quantity,
                            'reference_number': _referenceNumber,
                            'notes': _notes,
                            'reason': _notes,
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Inventory stock adjusted successfully')),
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                          );
                        } finally {
                          setDialogState(() {
                            _submitting = false;
                          });
                        }
                      }
                    },
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.isInventoryTracked) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: Text(
            'Inventory stock tracking is disabled for this item. Enable tracking to view movements.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    final movementsState = ref.watch(itemMovementsProvider(widget.item.id));

    return Column(
      children: [
        // Quick Action Bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Stock Level',
                    style: TextStyle(fontSize: 12.0, color: AppColors.textSecondaryLight),
                  ),
                  Text(
                    '${widget.item.stockQuantity.toStringAsFixed(2)} ${widget.item.unit ?? "units"}',
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAdjustStockDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.tune),
                label: const Text('Adjust Stock'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Movements List
        Expanded(
          child: movementsState.when(
            data: (movements) {
              if (movements.isEmpty) {
                return const Center(child: Text('No inventory movements recorded yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.m),
                itemCount: movements.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final move = movements[index];
                  final isAdd = move.quantityChange > 0;
                  final dateStr = move.entryDate != null
                      ? DateFormat('dd MMM yyyy').format(move.entryDate!)
                      : '—';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.s,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isAdd
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.danger.withValues(alpha: 0.1),
                      child: Icon(
                        isAdd ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isAdd ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    title: Text(
                      move.description ?? 'Stock Adjustment',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Ref: ${move.referenceNumber ?? "—"} • $dateStr',
                      style: const TextStyle(fontSize: 11.0),
                    ),
                    trailing: Text(
                      '${isAdd ? "+" : ""}${move.quantityChange.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: isAdd ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(err.toString(), style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
