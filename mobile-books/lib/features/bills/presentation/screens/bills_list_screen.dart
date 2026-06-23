import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/bills/data/models/bill.dart';
import 'package:mobile_books/features/bills/presentation/providers/bill_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

class BillsListScreen extends ConsumerStatefulWidget {
  const BillsListScreen({super.key});

  @override
  ConsumerState<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends ConsumerState<BillsListScreen> {
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(billSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bill> _sortBills(List<Bill> list, Map<int, String> vendorMap) {
    final sorted = List<Bill>.from(list);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'status':
          cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          break;
        case 'customer': // "Vendor Name" mapping
          final nameA = vendorMap[a.vendorId]?.toLowerCase() ?? '';
          final nameB = vendorMap[b.vendorId]?.toLowerCase() ?? '';
          cmp = nameA.compareTo(nameB);
          break;
        case 'date':
        default:
          cmp = a.billDate.compareTo(b.billDate);
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
                      _sortOptionChip(setModalState, 'customer', 'Vendor Name'),
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
    final billsState = ref.watch(filteredBillsProvider);
    final searchController = _searchController;
    final vendorsState = ref.watch(vendorsProvider);

    final vendors = vendorsState.value ?? [];
    final vendorMap = {for (var v in vendors) v.id: v.displayName};

    return ResponsiveScaffold(
      currentRoute: '/bills',
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
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
                  final sortedList = _sortBills(list, vendorMap);
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final bill = sortedList[index];
                      return _BillCard(bill: bill);
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: 6,
                  itemBuilder: (context, index) => LoadingSkeleton.skeletonListItem(),
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
