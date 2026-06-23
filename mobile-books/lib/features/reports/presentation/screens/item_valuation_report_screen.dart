import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';

class ItemValuationReportScreen extends ConsumerStatefulWidget {
  const ItemValuationReportScreen({super.key});

  @override
  ConsumerState<ItemValuationReportScreen> createState() => _ItemValuationReportScreenState();
}

class _ItemValuationReportScreenState extends ConsumerState<ItemValuationReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);

    return ResponsiveScaffold(
      currentRoute: '/reports/item-valuation',
      appBar: AppBar(
        title: const Text('Item Valuation Report'),
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
                // Filter items that are tracked for inventory valuation
                var trackedItems = items.where((item) => item.isInventoryTracked).toList();

                if (_searchQuery.isNotEmpty) {
                  trackedItems = trackedItems.where((item) {
                    return item.name.toLowerCase().contains(_searchQuery) ||
                        (item.sku ?? '').toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // Calculations
                double totalValue = 0.0;
                double totalQty = 0.0;
                for (final item in trackedItems) {
                  totalValue += item.stockQuantity * item.costPrice;
                  totalQty += item.stockQuantity;
                }

                return Column(
                  children: [
                    // Summary Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: AppColors.primaryBlue.withOpacity(0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.m),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Value',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _formatCurrency(totalValue),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.m),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Quantity',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        totalQty.toStringAsFixed(0),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
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
                    ),
                    const SizedBox(height: AppSpacing.s),
                    // Table Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(0.8),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.6),
                        },
                        children: const [
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.borderLight, width: 2),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Table Body
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                        itemCount: trackedItems.length,
                        itemBuilder: (context, index) {
                          final item = trackedItems[index];
                          final val = item.stockQuantity * item.costPrice;
                          return Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(0.8),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(1.6),
                            },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.borderLight),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Text(
                                      item.stockQuantity.toStringAsFixed(0),
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _formatCurrency(item.costPrice),
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _formatCurrency(val),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
