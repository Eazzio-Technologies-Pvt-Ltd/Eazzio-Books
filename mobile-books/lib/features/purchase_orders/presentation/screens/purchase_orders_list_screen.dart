import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/purchase_orders/data/models/purchase_order.dart';
import 'package:mobile_books/features/purchase_orders/presentation/providers/purchase_order_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class PurchaseOrdersListScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersListScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersListScreen> createState() => _PurchaseOrdersListScreenState();
}

class _PurchaseOrdersListScreenState extends ConsumerState<PurchaseOrdersListScreen> {
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(purchaseOrderSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PurchaseOrder> _sortPOs(List<PurchaseOrder> list) {
    final sorted = List<PurchaseOrder>.from(list);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'status':
          cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          break;
        case 'date':
        default:
          cmp = a.purchaseOrderDate.compareTo(b.purchaseOrderDate);
          break;
      }
      return _sortOrder == 'asc' ? cmp : -cmp;
    });
    return sorted;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.s,
                    children: [
                      _sortOptionChip(setModalState, 'date', 'Date'),
                      _sortOptionChip(setModalState, 'amount', 'Amount'),
                      _sortOptionChip(setModalState, 'status', 'Status'),
                    ],
                  ),
                  const Divider(),
                  const Text('Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Ascending'),
                        selected: _sortOrder == 'asc',
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _sortOrder = 'asc');
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.s),
                      ChoiceChip(
                        label: const Text('Descending'),
                        selected: _sortOrder == 'desc',
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _sortOrder = 'desc');
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortOptionChip(StateSetter setModalState, String val, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortBy == val,
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _sortBy = val);
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrdersState = ref.watch(filteredPurchaseOrdersProvider);
    final searchController = _searchController;

    return ResponsiveScaffold(
      currentRoute: '/purchase-orders',
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/purchase-orders/new'),
        child: const Icon(Icons.add),
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
              onChanged: (val) => ref.read(purchaseOrderSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search purchase orders...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(purchaseOrderSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // List Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(purchaseOrdersProvider.notifier).refresh(),
              child: purchaseOrdersState.when(
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No purchase orders found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final sortedList = _sortPOs(list);
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final po = sortedList[index];
                      return _PurchaseOrderCard(po: po);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
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
                          onPressed: () => ref.read(purchaseOrdersProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderCard extends ConsumerWidget {
  final PurchaseOrder po;

  const _PurchaseOrderCard({required this.po});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(vendorsProvider);
    final dateStr = DateFormat('dd MMM yyyy').format(po.purchaseOrderDate);

    String vendorName = 'Loading vendor...';
    vendorsState.whenData((vendors) {
      final vendor = vendors.where((v) => v.id == po.vendorId).firstOrNull;
      if (vendor != null) {
        vendorName = vendor.displayName;
      } else {
        vendorName = 'Vendor #${po.vendorId}';
      }
    });

    Color statusColor = AppColors.warning;
    if (po.status.toLowerCase() == 'open') {
      statusColor = AppColors.success;
    } else if (po.status.toLowerCase() == 'closed') {
      statusColor = AppColors.textSecondaryLight;
    } else if (po.status.toLowerCase() == 'cancelled') {
      statusColor = AppColors.danger;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => context.push('/purchase-orders/${po.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    po.purchaseOrderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      po.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                vendorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: $dateStr',
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${po.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
