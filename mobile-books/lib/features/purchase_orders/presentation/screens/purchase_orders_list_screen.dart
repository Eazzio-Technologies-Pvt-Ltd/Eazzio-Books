import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/purchase_orders/data/models/purchase_order.dart';
import 'package:mobile_books/features/purchase_orders/presentation/providers/purchase_order_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class PurchaseOrdersListScreen extends ConsumerWidget {
  const PurchaseOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseOrdersState = ref.watch(filteredPurchaseOrdersProvider);
    final searchController = TextEditingController(text: ref.read(purchaseOrderSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/purchase-orders',
      appBar: AppBar(
        title: const Text('Purchase Orders'),
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
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final po = list[index];
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
