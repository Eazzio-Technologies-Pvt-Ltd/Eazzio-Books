import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/expenses/data/models/expense.dart';
import 'package:mobile_books/features/expenses/presentation/providers/expense_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesState = ref.watch(filteredExpensesProvider);
    final searchController = TextEditingController(text: ref.read(expenseSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/expenses',
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/expenses/new'),
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
              onChanged: (val) => ref.read(expenseSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(expenseSearchQueryProvider.notifier).state = '';
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
              onRefresh: () => ref.read(expensesProvider.notifier).refresh(),
              child: expensesState.when(
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.payment, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No expenses found.',
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
                      final expense = list[index];
                      return _ExpenseCard(expense: expense);
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
                          onPressed: () => ref.read(expensesProvider.notifier).refresh(),
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

class _ExpenseCard extends ConsumerWidget {
  final Expense expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(vendorsProvider);
    final dateStr = DateFormat('dd MMM yyyy').format(expense.expenseDate);

    String vendorName = expense.vendorName ?? 'Loading vendor...';
    if (expense.vendorId != null && expense.vendorName == null) {
      vendorsState.whenData((vendors) {
        final vendor = vendors.where((v) => v.id == expense.vendorId).firstOrNull;
        if (vendor != null) {
          vendorName = vendor.displayName;
        } else {
          vendorName = 'Vendor #${expense.vendorId}';
        }
      });
    } else if (expense.vendorId == null) {
      vendorName = 'No Vendor';
    }

    Color statusColor = AppColors.warning;
    if (expense.status.toLowerCase() == 'paid') {
      statusColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => context.push('/expenses/${expense.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expense.category,
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
                      expense.status.toUpperCase(),
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
                    '₹${expense.amount.toStringAsFixed(2)}',
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
