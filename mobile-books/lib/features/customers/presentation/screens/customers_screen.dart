import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

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
        onPressed: () => context.push('/customers/new'),
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
                    label: const Text('Status'),
                    selected: _sortBy == 'status',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'status');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Name'),
                    selected: _sortBy == 'name',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'name');
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

          // Filters Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filter == null,
                  onSelected: (val) {
                    if (val) ref.read(customersListFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: AppSpacing.s),
                ChoiceChip(
                  label: const Text('Active'),
                  selected: filter == 'active',
                  onSelected: (val) {
                    if (val) ref.read(customersListFilterProvider.notifier).state = 'active';
                  },
                ),
                const SizedBox(width: AppSpacing.s),
                ChoiceChip(
                  label: const Text('Inactive'),
                  selected: filter == 'inactive',
                  onSelected: (val) {
                    if (val) ref.read(customersListFilterProvider.notifier).state = 'inactive';
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),

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
