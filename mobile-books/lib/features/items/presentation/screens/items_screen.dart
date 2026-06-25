import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';

import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

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
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) => ref.read(itemSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search items by name, SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(itemSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filters Bar (Scrollable chips row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filter == 'all',
                    onSelected: (val) {
                      if (val) ref.read(itemsListFilterProvider.notifier).state = 'all';
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  ChoiceChip(
                    label: const Text('Active'),
                    selected: filter == 'active',
                    onSelected: (val) {
                      if (val) ref.read(itemsListFilterProvider.notifier).state = 'active';
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  ChoiceChip(
                    label: const Text('Inactive'),
                    selected: filter == 'inactive',
                    onSelected: (val) {
                      if (val) ref.read(itemsListFilterProvider.notifier).state = 'inactive';
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  ChoiceChip(
                    label: const Text('Low Stock'),
                    selected: filter == 'low_stock',
                    onSelected: (val) {
                      if (val) ref.read(itemsListFilterProvider.notifier).state = 'low_stock';
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  ChoiceChip(
                    label: const Text('Goods'),
                    selected: filter == 'goods',
                    onSelected: (val) {
                      if (val) ref.read(itemsListFilterProvider.notifier).state = 'goods';
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  ChoiceChip(
                    label: const Text('Services'),
                    selected: filter == 'services',
                    onSelected: (val) {
                      if (val) ref.read(itemsListFilterProvider.notifier).state = 'services';
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

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
                                          ? AppColors.primaryBlue.withOpacity(0.1)
                                          : AppColors.warning.withOpacity(0.1),
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
                                            ? AppColors.danger.withOpacity(0.1)
                                            : AppColors.success.withOpacity(0.1),
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
