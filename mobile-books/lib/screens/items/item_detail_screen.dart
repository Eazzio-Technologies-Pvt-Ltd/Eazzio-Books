import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/item_model.dart';
import '../../providers/item_provider.dart';
import '../../widgets/common/app_button.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final int itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this inventory item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      final success = await ref.read(itemProvider.notifier).removeItem(widget.itemId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully'), backgroundColor: AppColors.success),
          );
          context.pop();
        }
      } else {
        setState(() => _isDeleting = false);
        if (mounted) {
          final error = ref.read(itemProvider).errorMessage ?? 'Failed to delete item';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemState = ref.watch(itemProvider);
    
    // Find the item in state list, or fallback
    final item = itemState.items.firstWhere(
      (element) => element.id == widget.itemId,
      orElse: () => ItemModel(
        id: 0,
        name: 'Loading...',
        taxRate: 0.0,
        itemType: 'Goods',
        sellingPrice: 0.0,
        costPrice: 0.0,
        isInventoryTracked: false,
        openingStock: 0.0,
        openingStockRate: 0.0,
        reorderLevel: 0.0,
        stockQuantity: 0.0,
      ),
    );

    if (item.id == 0) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(item.name, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              context.push('/items/${item.id}/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.itemType == 'Service'
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.itemType,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: item.itemType == 'Service'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF7E22CE),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('SKU: ${item.sku ?? '-'}', style: AppTextStyles.bodyMedium),
                  const Divider(height: 24, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderInfoItem('SELLING PRICE', AppFormatters.formatCurrency(item.sellingPrice)),
                      _buildHeaderInfoItem('COST PRICE', AppFormatters.formatCurrency(item.costPrice)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Inventory Stock Status Card
            if (item.isInventoryTracked) ...[
              _buildSectionCard(
                title: 'INVENTORY INFORMATION',
                child: Column(
                  children: [
                    _buildRowItem('Current Stock', '${item.stockQuantity.toStringAsFixed(0)} ${item.unit ?? 'pcs'}', isHighlighted: true),
                    _buildRowItem('Reorder Level', '${item.reorderLevel.toStringAsFixed(0)} ${item.unit ?? 'pcs'}'),
                    _buildRowItem('Opening Stock', '${item.openingStock.toStringAsFixed(0)} ${item.unit ?? 'pcs'}'),
                    _buildRowItem('Opening Rate', AppFormatters.formatCurrency(item.openingStockRate)),
                    _buildRowItem('Inventory Account', item.inventoryAccount ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Product Parameters & Tax Card
            _buildSectionCard(
              title: 'SALES & TAX DETAILS',
              child: Column(
                children: [
                  _buildRowItem('Tax Rate', '${item.taxRate.toStringAsFixed(1)}%'),
                  _buildRowItem('HSN Code', item.hsnCode ?? '-'),
                  _buildRowItem('Unit Measurement', item.unit ?? '-'),
                  _buildRowItem('Sales Account', item.salesAccount ?? '-'),
                  _buildRowItem('Purchase Account', item.purchaseAccount ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Description Card
            if (item.description != null && item.description!.isNotEmpty) ...[
              _buildSectionCard(
                title: 'DESCRIPTION',
                child: Text(
                  item.description!,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
            ],
            AppButton(
              text: 'Edit Product',
              onPressed: () => context.push('/items/${item.id}/edit'),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Delete Product',
              variant: AppButtonVariant.ghost,
              onPressed: _isDeleting ? null : _handleDelete,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({String? title, required Widget child}) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(height: 20, color: AppColors.border),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildHeaderInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.numeric.copyWith(fontSize: 18, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildRowItem(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: isHighlighted
                ? AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
