import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/item_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_skeleton.dart';
import '../../widgets/common/staggered_fade_in.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemState = ref.watch(itemProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          'Inventory Items',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(itemProvider.notifier).fetchItems(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textHint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search items by name or SKU...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textHint, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          // Main Body Content
          Expanded(
            child: _buildBody(itemState),
          ),
        ],
      ),
      // FAB in thumb zone
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 6,
        onPressed: () {
          context.push('/items/new');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(ItemState state) {
    if (state.isLoading && state.items.isEmpty) {
      // 1. Loading State: Shimmer skeleton list
      return ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingSkeleton.skeletonListItem(),
        ),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      // 2. Error State: Error display with retry
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading items',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => ref.read(itemProvider.notifier).fetchItems(),
                icon: const Icon(Icons.replay),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter items based on query
    final filteredItems = state.items.where((item) {
      final nameMatches = item.name.toLowerCase().contains(_searchQuery);
      final skuMatches = (item.sku ?? '').toLowerCase().contains(_searchQuery);
      return nameMatches || skuMatches;
    }).toList();

    if (filteredItems.isEmpty) {
      // 3. Empty State: Ilustrations + CTA
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: _searchQuery.isNotEmpty ? 'No matches found' : 'No items added yet',
          description: _searchQuery.isNotEmpty
              ? 'Try modifying your search keywords or clear the filter.'
              : 'Add inventory items to track product values, stock quantities, and prices.',
          ctaText: _searchQuery.isNotEmpty ? null : 'Add First Item',
          onCtaPressed: _searchQuery.isNotEmpty ? null : () => context.push('/items/new'),
        ),
      );
    }

    // 4. Data State: Staggered Fade-in list
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(itemProvider.notifier).fetchItems(),
      child: ListView.builder(
        itemCount: filteredItems.length,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          final delay = Duration(milliseconds: 40 * index);
          final animationDelay = delay.inMilliseconds > 300 ? const Duration(milliseconds: 300) : delay;

          return StaggeredFadeIn(
            delay: animationDelay,
            child: Card(
              color: AppColors.bgCard,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Item Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.itemType == 'Service'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.itemType,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: item.itemType == 'Service'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF7E22CE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      item.sku != null && item.sku!.isNotEmpty ? 'SKU: ${item.sku}' : 'No SKU',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELLING PRICE',
                              style: AppTextStyles.caption.copyWith(fontSize: 9),
                            ),
                            Text(
                              AppFormatters.formatCurrency(item.sellingPrice),
                              style: AppTextStyles.numeric.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                        // Stock quantity (if tracked)
                        if (item.isInventoryTracked)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'STOCK STATUS',
                                style: AppTextStyles.caption.copyWith(fontSize: 9),
                              ),
                              Text(
                                '${item.stockQuantity.toStringAsFixed(0)} ${item.unit ?? 'pcs'}',
                                style: AppTextStyles.numeric.copyWith(
                                  fontSize: 14,
                                  color: item.stockQuantity <= item.reorderLevel
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  context.push('/items/${item.id}');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
