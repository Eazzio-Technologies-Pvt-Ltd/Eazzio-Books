import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/payments_made/data/models/payment_made.dart';
import 'package:mobile_books/features/payments_made/presentation/providers/payment_made_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

class PaymentsMadeListScreen extends ConsumerStatefulWidget {
  const PaymentsMadeListScreen({super.key});

  @override
  ConsumerState<PaymentsMadeListScreen> createState() => _PaymentsMadeListScreenState();
}

class _PaymentsMadeListScreenState extends ConsumerState<PaymentsMadeListScreen> {
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(paymentMadeSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentMade> _sortPaymentsMade(List<PaymentMade> list, Map<int, String> vendorMap) {
    final sorted = List<PaymentMade>.from(list);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        case 'status':
          // Sort by payment mode
          final modeA = a.paymentMode ?? '';
          final modeB = b.paymentMode ?? '';
          cmp = modeA.toLowerCase().compareTo(modeB.toLowerCase());
          break;
        case 'name':
          final nameA = a.vendorName ?? (a.vendorId != null ? vendorMap[a.vendorId] : null) ?? '';
          final nameB = b.vendorName ?? (b.vendorId != null ? vendorMap[b.vendorId] : null) ?? '';
          cmp = nameA.toLowerCase().compareTo(nameB.toLowerCase());
          break;
        case 'date':
        default:
          cmp = a.paymentDate.compareTo(b.paymentDate);
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
                      _sortOptionChip(setModalState, 'status', 'Payment Mode'),
                      _sortOptionChip(setModalState, 'name', 'Vendor Name'),
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
    final paymentsState = ref.watch(filteredPaymentsMadeProvider);
    final searchController = _searchController;
    final vendorsState = ref.watch(vendorsProvider);

    final vendors = vendorsState.value ?? [];
    final vendorMap = {for (var v in vendors) v.id: v.displayName};

    return ResponsiveScaffold(
      currentRoute: '/payments-made',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bills/0/record-payment?balanceDue=0.0'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: const Text('Payments Made'),
      ),
      body: Column(
        children: [
          // Search Bar & Actions Row
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
                    onChanged: (val) => ref.read(paymentMadeSearchQueryProvider.notifier).state = val,
                    decoration: InputDecoration(
                      hintText: 'Search payments...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                ref.read(paymentMadeSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.primaryBlue),
                  onSelected: (val) {
                    if (val == 'sort') {
                      _showSortBottomSheet(context);
                    } else if (val == 'refresh') {
                      ref.read(paymentsMadeProvider.notifier).refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payments list refreshed'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (val == 'import') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Importing payments...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (val == 'export') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payments exported successfully to downloads'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sort',
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 18),
                          SizedBox(width: 8),
                          Text('Sort Payments'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 18),
                          SizedBox(width: 8),
                          Text('Refresh List'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.file_download_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Import Payments'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.file_upload_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Export Payments'),
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
              onRefresh: () => ref.read(paymentsMadeProvider.notifier).refresh(),
              child: paymentsState.when(
                data: (list) {
                  final sortedList = _sortPaymentsMade(list, vendorMap);

                  if (sortedList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.payment, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No payments recorded.',
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
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final pm = sortedList[index];
                      return _PaymentMadeCard(pm: pm);
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: 5,
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
                          onPressed: () => ref.read(paymentsMadeProvider.notifier).refresh(),
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

class _PaymentMadeCard extends ConsumerWidget {
  final PaymentMade pm;

  const _PaymentMadeCard({required this.pm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(vendorsProvider);
    final dateStr = DateFormat('dd MMM yyyy').format(pm.paymentDate);

    String vendorName = pm.vendorName ?? 'Loading vendor...';
    if (pm.vendorId != null && pm.vendorName == null) {
      vendorsState.whenData((vendors) {
        final vendor = vendors.where((v) => v.id == pm.vendorId).firstOrNull;
        if (vendor != null) {
          vendorName = vendor.displayName;
        } else {
          vendorName = 'Vendor #${pm.vendorId}';
        }
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pm.billNumber != null ? 'Bill: ${pm.billNumber}' : 'Payment Reference',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  '₹${pm.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                if (pm.paymentMode != null)
                  Text(
                    pm.paymentMode!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
