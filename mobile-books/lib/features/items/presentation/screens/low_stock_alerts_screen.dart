import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';

class LowStockAlertsScreen extends ConsumerStatefulWidget {
  const LowStockAlertsScreen({super.key});

  @override
  ConsumerState<LowStockAlertsScreen> createState() => _LowStockAlertsScreenState();
}

class _LowStockAlertsScreenState extends ConsumerState<LowStockAlertsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);

    return ResponsiveScaffold(
      currentRoute: '/inventory/low-stock',
      appBar: AppBar(
        title: const Text('Low Stock Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(itemsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: itemsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              data: (items) {
                // Filter items that are tracked and stock <= reorder level
                var lowStockItems = items.where((item) {
                  return item.isInventoryTracked && item.stockQuantity <= item.reorderLevel;
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  lowStockItems = lowStockItems.where((item) {
                    return item.name.toLowerCase().contains(_searchQuery) ||
                        (item.sku ?? '').toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (lowStockItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'All stock levels are healthy!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: lowStockItems.length,
                  itemBuilder: (context, index) {
                    final item = lowStockItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.xs,
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(AppSpacing.s),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('SKU: ${item.sku ?? '—'}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Stock: ${item.stockQuantity.toStringAsFixed(0)} ${item.unit ?? ''}',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Min: ${item.reorderLevel.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.push('/items/${item.id}');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
