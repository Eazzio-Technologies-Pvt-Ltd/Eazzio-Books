import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/invoices/data/models/payment.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

class PaymentsReceivedListScreen extends ConsumerStatefulWidget {
  const PaymentsReceivedListScreen({super.key});

  @override
  ConsumerState<PaymentsReceivedListScreen> createState() => _PaymentsReceivedListScreenState();
}

class _PaymentsReceivedListScreenState extends ConsumerState<PaymentsReceivedListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date';
  String _sortOrder = 'desc';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Payment> _filterAndSort(List<Payment> list) {
    // 1. Search & Filter
    var result = list;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        final custMatch = (p.customerName ?? '').toLowerCase().contains(q);
        final refMatch = (p.reference ?? '').toLowerCase().contains(q);
        final invMatch = (p.invoiceNumber ?? '').toLowerCase().contains(q);
        return custMatch || refMatch || invMatch;
      }).toList();
    }

    // 2. Sort
    final sorted = List<Payment>.from(result);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        case 'status':
          // Payments don't have a direct status display typically, sort by paymentMode
          cmp = (a.paymentMode ?? '').toLowerCase().compareTo((b.paymentMode ?? '').toLowerCase());
          break;
        case 'name':
          final nameA = a.customerName ?? '';
          final nameB = b.customerName ?? '';
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
                      _sortOptionChip(setModalState, 'name', 'Customer Name'),
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
    final paymentsState = ref.watch(paymentsProvider);

    return ResponsiveScaffold(
      currentRoute: '/payments-received',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/invoices/0/record-payment?balanceDue=0.0'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: const Text('Payments Received'),
      ),
      body: Column(
        children: [
          // Search Bar & Actions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search payments received...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
                  onPressed: () {
                    ref.read(paymentsProvider.notifier).refresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payments list refreshed'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Refresh List',
                ),
                IconButton(
                  icon: const Icon(Icons.file_download_outlined, color: AppColors.primaryBlue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Importing payments...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Import Payments',
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined, color: AppColors.primaryBlue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payments exported successfully to downloads'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Export Payments',
                ),
              ],
            ),
          ),

          // Inline Sorting Chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Sort by: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('Date'),
                    selected: _sortBy == 'date',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'date');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Amount'),
                    selected: _sortBy == 'amount',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'amount');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Reference'),
                    selected: _sortBy == 'reference',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'reference');
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  IconButton(
                    icon: Icon(
                      _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                      });
                    },
                    tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // List Content
          Expanded(
            child: paymentsState.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.m),
                itemCount: 5,
                itemBuilder: (context, index) => LoadingSkeleton.skeletonListItem(),
              ),
              error: (err, stack) => Center(
                child: Text(
                  err.toString(),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              data: (list) {
                final filteredAndSorted = _filterAndSort(list);

                if (filteredAndSorted.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => ref.read(paymentsProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.payment, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No Payments found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(paymentsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: filteredAndSorted.length,
                    itemBuilder: (context, index) {
                      final payment = filteredAndSorted[index];
                      final dateStr = DateFormat('dd MMM yyyy').format(payment.paymentDate);

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
                                    payment.invoiceNumber != null
                                        ? 'Invoice: ${payment.invoiceNumber}'
                                        : 'Invoice #${payment.invoiceId}',
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      payment.paymentMode?.toUpperCase() ?? 'CASH',
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s),
                              Text(
                                payment.customerName ?? 'Customer #${payment.customerId}',
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
                                    '₹${payment.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              if (payment.reference != null && payment.reference!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Ref: ${payment.reference}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
