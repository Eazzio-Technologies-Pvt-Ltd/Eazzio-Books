import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';

import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(filteredCustomersProvider);
    final filter = ref.watch(customersListFilterProvider);
    final searchController = TextEditingController(text: ref.read(customerSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/customers',
      appBar: AppBar(
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
                  if (customers.isEmpty) {
                    return const Center(
                      child: Text('No customers found.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
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
