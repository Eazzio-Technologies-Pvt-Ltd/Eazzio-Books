import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan.dart';
import 'package:mobile_books/features/delivery_challans/presentation/providers/delivery_challan_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

const Map<String, _StatusStyle> _statusStyles = {
  'draft':     _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'DRAFT', Icons.edit_note),
  'delivered': _StatusStyle(Color(0xFFF0FDF4), Color(0xFF15803D), 'DELIVERED', Icons.check_circle_outline),
  'cancelled': _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'CANCELLED', Icons.cancel_outlined),
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

class DeliveryChallansListScreen extends ConsumerStatefulWidget {
  const DeliveryChallansListScreen({super.key});

  @override
  ConsumerState<DeliveryChallansListScreen> createState() => _DeliveryChallansListScreenState();
}

class _DeliveryChallansListScreenState extends ConsumerState<DeliveryChallansListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  String _statusFilter = 'all'; // 'all', 'draft', 'delivered', 'cancelled'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeliveryChallan> _filterAndSort(List<DeliveryChallan> list, Map<int, String> customerMap) {
    // 1. Search & Filter
    var result = list;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((dc) {
        final numMatch = dc.deliveryChallanNumber.toLowerCase().contains(q);
        final custName = customerMap[dc.customerId]?.toLowerCase() ?? '';
        final custMatch = custName.contains(q);
        return numMatch || custMatch;
      }).toList();
    }

    if (_statusFilter != 'all') {
      result = result.where((dc) => dc.status.toLowerCase() == _statusFilter).toList();
    }

    // 2. Sort
    final sorted = List<DeliveryChallan>.from(result);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          // Delivery challan does not have amount directly, let's sort by adjustment or id
          cmp = (a.adjustment ?? 0.0).compareTo(b.adjustment ?? 0.0);
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
          cmp = a.challanDate.compareTo(b.challanDate);
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
    final challansState = ref.watch(deliveryChallansProvider);
    final customersState = ref.watch(customersProvider);

    final customers = customersState.value ?? [];
    final customerMap = {
      for (var c in customers)
        c.id: (c.displayName ?? '${c.firstName ?? ""} ${c.lastName ?? ""}'.trim())
    };

    return ResponsiveScaffold(
      currentRoute: '/delivery-challans',
      appBar: AppBar(
        title: const Text('Delivery Challans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/delivery-challans/new'),
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
                hintText: 'Search delivery challans...',
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
                  _filterChip('draft', 'Draft'),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('delivered', 'Delivered'),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('cancelled', 'Cancelled'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // List Content
          Expanded(
            child: challansState.when(
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
                    onRefresh: () => ref.read(deliveryChallansProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No Delivery Challans found',
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
                  onRefresh: () => ref.read(deliveryChallansProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: filteredAndSorted.length,
                    itemBuilder: (context, index) {
                      final dc = filteredAndSorted[index];
                      return _ChallanCard(dc: dc);
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

class _ChallanCard extends ConsumerWidget {
  final DeliveryChallan dc;

  const _ChallanCard({required this.dc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);
    final statusStyle = _getStatusStyle(dc.status);
    final dateStr = DateFormat('dd MMM yyyy').format(dc.challanDate);

    String customerName = 'Loading customer...';
    customersState.whenData((customers) {
      final customer = customers.where((c) => c.id == dc.customerId).firstOrNull;
      if (customer != null) {
        customerName = customer.displayName ??
            '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim();
        if (customerName.isEmpty) {
          customerName = customer.email ?? 'Customer #${dc.customerId}';
        }
      } else {
        customerName = 'Customer #${dc.customerId}';
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => context.push('/delivery-challans/${dc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dc.deliveryChallanNumber,
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
                    'Date: $dateStr',
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  if (dc.deliveryDate != null)
                    Text(
                      'Delivery: ${DateFormat('dd MMM yyyy').format(dc.deliveryDate!)}',
                      style: const TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
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
