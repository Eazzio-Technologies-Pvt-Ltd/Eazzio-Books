import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/bills/data/models/bill.dart';
import 'package:mobile_books/features/bills/presentation/providers/bill_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class BillsListScreen extends ConsumerWidget {
  const BillsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsState = ref.watch(filteredBillsProvider);
    final searchController = TextEditingController(text: ref.read(billSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/bills',
      appBar: AppBar(
        title: const Text('Bills'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bills/new'),
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
              onChanged: (val) => ref.read(billSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search bills...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(billSearchQueryProvider.notifier).state = '';
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
              onRefresh: () => ref.read(billsProvider.notifier).refresh(),
              child: billsState.when(
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No bills found.',
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
                      final bill = list[index];
                      return _BillCard(bill: bill);
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
                          onPressed: () => ref.read(billsProvider.notifier).refresh(),
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

class _BillCard extends ConsumerWidget {
  final Bill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(vendorsProvider);
    final dateStr = DateFormat('dd MMM yyyy').format(bill.billDate);

    String vendorName = 'Loading vendor...';
    vendorsState.whenData((vendors) {
      final vendor = vendors.where((v) => v.id == bill.vendorId).firstOrNull;
      if (vendor != null) {
        vendorName = vendor.displayName;
      } else {
        vendorName = 'Vendor #${bill.vendorId}';
      }
    });

    Color statusColor = AppColors.warning;
    if (bill.status.toLowerCase() == 'paid') {
      statusColor = AppColors.success;
    } else if (bill.status.toLowerCase() == 'partially_paid') {
      statusColor = Colors.orange;
    } else if (bill.status.toLowerCase() == 'void') {
      statusColor = AppColors.danger;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => context.push('/bills/${bill.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bill.billNumber,
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
                      bill.status.toUpperCase().replaceAll('_', ' '),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (bill.balanceDue > 0 && bill.balanceDue != bill.totalAmount)
                        Text(
                          'Due: ₹${bill.balanceDue.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.danger),
                        ),
                    ],
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
