import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';
import 'package:mobile_books/core/permissions/plan_gate_service.dart';
import 'package:mobile_books/widgets/common/upgrade_continue_sheet.dart';
import 'package:mobile_books/widgets/common/plan_limit_banner.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(customerSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _sortCustomers(List<Customer> list) {
    final sorted = List<Customer>.from(list);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.openingBalance.compareTo(b.openingBalance);
          break;
        case 'status':
          final statusA = a.isActive ? 'active' : 'inactive';
          final statusB = b.isActive ? 'active' : 'inactive';
          cmp = statusA.compareTo(statusB);
          break;
        case 'name':
          cmp = a.formattedName.toLowerCase().compareTo(b.formattedName.toLowerCase());
          break;
        case 'date':
        default:
          final dateA = a.createdAt ?? DateTime(1970);
          final dateB = b.createdAt ?? DateTime(1970);
          cmp = dateA.compareTo(dateB);
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

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(filteredCustomersProvider);
    final filter = ref.watch(customersListFilterProvider);
    final searchController = _searchController;

    return ResponsiveScaffold(
      currentRoute: '/customers',
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Customers'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final planGate = ref.read(planGateProvider);
          if (!planGate.canCreate('customer')) {
            final limit = planGate.getMaxLimit('customer') ?? 10;
            final currentPlanName = planGate.planId.toLowerCase() == 'free' ? 'Free' : 'Standard Premium';
            UpgradeContinueSheet.show(
              context,
              title: 'Customer Limit Reached',
              description: 'You have reached the maximum limit of $limit customers allowed on the $currentPlanName plan. Upgrade to a higher plan to add more.',
            );
          } else {
            context.push('/customers/new');
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
            child: const PlanLimitBanner(resourceType: 'customer', resourceName: 'customer'),
          ),
          // Search Bar & Filter Menu
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
                    onChanged: (val) => ref.read(customerSearchQueryProvider.notifier).state = val,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                ref.read(customerSearchQueryProvider.notifier).state = '';
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
                    if (val == 'sort_date') {
                      setState(() => _sortBy = 'date');
                    } else if (val == 'sort_amount') {
                      setState(() => _sortBy = 'amount');
                    } else if (val == 'sort_status') {
                      setState(() => _sortBy = 'status');
                    } else if (val == 'sort_name') {
                      setState(() => _sortBy = 'name');
                    } else if (val == 'order_asc') {
                      setState(() => _sortOrder = 'asc');
                    } else if (val == 'order_desc') {
                      setState(() => _sortOrder = 'desc');
                    } else if (val == 'filter_all') {
                      ref.read(customersListFilterProvider.notifier).state = null;
                    } else if (val == 'filter_active') {
                      ref.read(customersListFilterProvider.notifier).state = 'active';
                    } else if (val == 'filter_inactive') {
                      ref.read(customersListFilterProvider.notifier).state = 'inactive';
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      enabled: false,
                      child: Text('SORT BY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    ),
                    PopupMenuItem(
                      value: 'sort_date',
                      child: Row(
                        children: [
                          const Text('Date'),
                          if (_sortBy == 'date') const Spacer(),
                          if (_sortBy == 'date') const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sort_amount',
                      child: Row(
                        children: [
                          const Text('Amount'),
                          if (_sortBy == 'amount') const Spacer(),
                          if (_sortBy == 'amount') const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sort_status',
                      child: Row(
                        children: [
                          const Text('Status'),
                          if (_sortBy == 'status') const Spacer(),
                          if (_sortBy == 'status') const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sort_name',
                      child: Row(
                        children: [
                          const Text('Name'),
                          if (_sortBy == 'name') const Spacer(),
                          if (_sortBy == 'name') const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      enabled: false,
                      child: Text('ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    ),
                    PopupMenuItem(
                      value: 'order_asc',
                      child: Row(
                        children: [
                          const Text('Ascending'),
                          if (_sortOrder == 'asc') const Spacer(),
                          if (_sortOrder == 'asc') const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'order_desc',
                      child: Row(
                        children: [
                          const Text('Descending'),
                          if (_sortOrder == 'desc') const Spacer(),
                          if (_sortOrder == 'desc') const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      enabled: false,
                      child: Text('FILTER BY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    ),
                    PopupMenuItem(
                      value: 'filter_all',
                      child: Row(
                        children: [
                          const Text('All'),
                          if (filter == null) const Spacer(),
                          if (filter == null) const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter_active',
                      child: Row(
                        children: [
                          const Text('Active'),
                          if (filter == 'active') const Spacer(),
                          if (filter == 'active') const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter_inactive',
                      child: Row(
                        children: [
                          const Text('Inactive'),
                          if (filter == 'inactive') const Spacer(),
                          if (filter == 'inactive') const Icon(Icons.check, size: 16),
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
              onRefresh: () => ref.read(customersProvider.notifier).refresh(),
              child: customersState.when(
                data: (customers) {
                  final sortedCustomers = _sortCustomers(customers);

                  if (sortedCustomers.isEmpty) {
                    return const Center(
                      child: Text('No customers found.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: sortedCustomers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer = sortedCustomers[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.s,
                        ),
                        title: Text(
                          customer.formattedName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.companyName != null && customer.companyName!.isNotEmpty)
                              Text(customer.companyName!),
                            if (customer.email != null) Text(customer.email!),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: customer.isActive
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.textSecondaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            customer.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              color: customer.isActive ? AppColors.success : AppColors.textSecondaryLight,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => context.push('/customers/${customer.id}'),
                      );
                    },
                  );
                },
                loading: () => ListView.builder(
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
                          onPressed: () => ref.read(customersProvider.notifier).refresh(),
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
