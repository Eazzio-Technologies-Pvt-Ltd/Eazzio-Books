import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';

import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(itemSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(filteredItemsProvider);
    final filter = ref.watch(itemsListFilterProvider);
    final searchController = _searchController;

    return ResponsiveScaffold(
      currentRoute: '/items',
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Items & Inventory'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/items/new'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(AppIcons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar & Filter Menu
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (val) => ref.read(itemSearchQueryProvider.notifier).state = val,
                    decoration: InputDecoration(
                      hintText: 'Search items by name, SKU...',
                      prefixIcon: const Icon(AppIcons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(AppIcons.clear),
                              onPressed: () {
                                searchController.clear();
                                ref.read(itemSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                PopupMenuButton<String>(
                  icon: const Icon(AppIcons.more_vert, color: AppColors.primaryBlue),
                  onSelected: (val) {
                    ref.read(itemsListFilterProvider.notifier).state = val;
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'all',
                      child: Row(
                        children: [
                          const Text('All Items'),
                          if (filter == 'all') const Spacer(),
                          if (filter == 'all') const Icon(AppIcons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'active',
                      child: Row(
                        children: [
                          const Text('Active Items'),
                          if (filter == 'active') const Spacer(),
                          if (filter == 'active') const Icon(AppIcons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'inactive',
                      child: Row(
                        children: [
                          const Text('Inactive Items'),
                          if (filter == 'inactive') const Spacer(),
                          if (filter == 'inactive') const Icon(AppIcons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'low_stock',
                      child: Row(
                        children: [
                          const Text('Low Stock'),
                          if (filter == 'low_stock') const Spacer(),
                          if (filter == 'low_stock') const Icon(AppIcons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'goods',
                      child: Row(
                        children: [
                          const Text('Goods'),
                          if (filter == 'goods') const Spacer(),
                          if (filter == 'goods') const Icon(AppIcons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'services',
                      child: Row(
                        children: [
                          const Text('Services'),
                          if (filter == 'services') const Spacer(),
                          if (filter == 'services') const Icon(AppIcons.check, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // List Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(itemsProvider.notifier).refresh(),
              child: itemsState.when(
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No items found.',
                            style: TextStyle(color: AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isGoods = item.itemType.toLowerCase() == 'goods';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.s,
                        ),
                        title: Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 16.0,
                              ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.sku != null && item.sku!.isNotEmpty)
                                Text('SKU: ${item.sku}', style: const TextStyle(fontSize: 12.0)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s,
                                      vertical: AppSpacing.xs / 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isGoods
                                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                                          : AppColors.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      item.itemType.toUpperCase(),
                                      style: TextStyle(
                                        color: isGoods ? AppColors.primaryBlue : AppColors.warning,
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  // Stock Badge (if tracked)
                                  if (item.isInventoryTracked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s,
                                        vertical: AppSpacing.xs / 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.stockQuantity <= item.reorderLevel
                                            ? AppColors.danger.withValues(alpha: 0.1)
                                            : AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: Text(
                                        'STOCK: ${item.stockQuantity.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: item.stockQuantity <= item.reorderLevel
                                              ? AppColors.danger
                                              : AppColors.success,
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${item.sellingPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                            const Text(
                              'Selling Price',
                              style: TextStyle(
                                fontSize: 10.0,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/items/${item.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            ElevatedButton(
                              onPressed: () => ref.read(itemsProvider.notifier).refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
