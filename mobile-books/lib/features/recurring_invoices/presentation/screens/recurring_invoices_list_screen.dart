import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice.dart';
import 'package:mobile_books/features/recurring_invoices/presentation/providers/recurring_invoice_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

const Map<String, _StatusStyle> _statusStyles = {
  'active':  _StatusStyle(Color(0xFFF0FDF4), Color(0xFF15803D), 'ACTIVE', Icons.play_circle_fill),
  'paused':  _StatusStyle(Color(0xFFFFFBEB), Color(0xFFB45309), 'PAUSED', Icons.pause_circle_filled),
  'stopped': _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'STOPPED', Icons.stop_circle_rounded),
};

class _StatusStyle {
  final Color bg;
  final Color color;
  final String label;
  final IconData icon;
  const _StatusStyle(this.bg, this.color, this.label, this.icon);
}

_StatusStyle _getStatusStyle(String status) {
  return _statusStyles[status.toLowerCase()] ??
      const _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'UNKNOWN', Icons.help_outline);
}

class RecurringInvoicesListScreen extends ConsumerStatefulWidget {
  const RecurringInvoicesListScreen({super.key});

  @override
  ConsumerState<RecurringInvoicesListScreen> createState() => _RecurringInvoicesListScreenState();
}

class _RecurringInvoicesListScreenState extends ConsumerState<RecurringInvoicesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  String _statusFilter = 'all'; // 'all', 'active', 'paused', 'stopped'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecurringInvoice> _filterAndSort(List<RecurringInvoice> list, Map<int, String> customerMap) {
    // 1. Search & Filter
    var result = list;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((ri) {
        final nameMatch = ri.profileName.toLowerCase().contains(q);
        final custName = customerMap[ri.customerId]?.toLowerCase() ?? '';
        final custMatch = custName.contains(q);
        return nameMatch || custMatch;
      }).toList();
    }

    if (_statusFilter != 'all') {
      result = result.where((ri) => ri.status.toLowerCase() == _statusFilter).toList();
    }

    // 2. Sort
    final sorted = List<RecurringInvoice>.from(result);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.total.compareTo(b.total);
          break;
        case 'status':
          cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          break;
        case 'name':
          final nameA = customerMap[a.customerId]?.toLowerCase() ?? '';
          final nameB = customerMap[b.customerId]?.toLowerCase() ?? '';
          cmp = nameA.compareTo(nameB);
          break;
        case 'date':
        default:
          cmp = a.startDate.compareTo(b.startDate);
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

  Widget _filterChip(String val, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == val,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = val;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(recurringInvoicesProvider);
    final customersState = ref.watch(customersProvider);

    final customers = customersState.value ?? [];
    final customerMap = {
      for (var c in customers)
        c.id: (c.displayName ?? '${c.firstName ?? ""} ${c.lastName ?? ""}'.trim())
    };

    return ResponsiveScaffold(
      currentRoute: '/recurring-invoices',
      appBar: AppBar(
        title: const Text('Recurring Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recurring-invoices/new'),
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
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search recurring profiles...',
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

          // Status Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'All'),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('active', 'Active'),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('paused', 'Paused'),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('stopped', 'Stopped'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // List Content
          Expanded(
            child: listState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  err.toString(),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              data: (list) {
                final filteredAndSorted = _filterAndSort(list, customerMap);

                if (filteredAndSorted.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => ref.read(recurringInvoicesProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.autorenew, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No Recurring Profiles found',
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
                  onRefresh: () => ref.read(recurringInvoicesProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: filteredAndSorted.length,
                    itemBuilder: (context, index) {
                      final ri = filteredAndSorted[index];
                      return _RecurringInvoiceCard(ri: ri);
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

class _RecurringInvoiceCard extends ConsumerWidget {
  final RecurringInvoice ri;

  const _RecurringInvoiceCard({required this.ri});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);
    final statusStyle = _getStatusStyle(ri.status);
    final dateStr = DateFormat('dd MMM yyyy').format(ri.startDate);

    String customerName = 'Loading customer...';
    customersState.whenData((customers) {
      final customer = customers.where((c) => c.id == ri.customerId).firstOrNull;
      if (customer != null) {
        customerName = customer.displayName ??
            '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim();
        if (customerName.isEmpty) {
          customerName = customer.email ?? 'Customer #${ri.customerId}';
        }
      } else {
        customerName = 'Customer #${ri.customerId}';
      }
    });

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
                Expanded(
                  child: Text(
                    ri.profileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusStyle.bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusStyle.icon, size: 14, color: statusStyle.color),
                      const SizedBox(width: 4),
                      Text(
                        statusStyle.label,
                        style: TextStyle(
                          color: statusStyle.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              customerName,
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
                  'Freq: ${ri.frequency} | Start: $dateStr',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '₹${ri.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ri.status == 'Active') ...[
                  TextButton.icon(
                    icon: const Icon(Icons.pause, size: 16),
                    label: const Text('Pause'),
                    onPressed: () => ref.read(recurringInvoicesProvider.notifier).pauseRecurringInvoice(ri.id),
                  ),
                ] else if (ri.status == 'Paused') ...[
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Resume'),
                    onPressed: () => ref.read(recurringInvoicesProvider.notifier).resumeRecurringInvoice(ri.id),
                  ),
                ],
                if (ri.status != 'Stopped') ...[
                  TextButton.icon(
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Stop'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () => ref.read(recurringInvoicesProvider.notifier).stopRecurringInvoice(ri.id),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Gen Now'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    onPressed: () async {
                      try {
                        final invoiceId = await ref.read(recurringInvoicesProvider.notifier).generateNow(ri.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invoice generated successfully.')),
                          );
                          context.push('/invoices/$invoiceId');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }
}
