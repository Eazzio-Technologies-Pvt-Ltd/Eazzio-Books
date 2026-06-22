import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/recurring_expenses/data/models/recurring_expense.dart';
import 'package:mobile_books/features/recurring_expenses/presentation/providers/recurring_expense_provider.dart';

class RecurringExpensesListScreen extends ConsumerStatefulWidget {
  const RecurringExpensesListScreen({super.key});

  @override
  ConsumerState<RecurringExpensesListScreen> createState() => _RecurringExpensesListScreenState();
}

class _RecurringExpensesListScreenState extends ConsumerState<RecurringExpensesListScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(filteredRecurringExpensesProvider);
    final searchController = TextEditingController(text: ref.read(recurringExpenseSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/recurring-expenses',
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recurring-expenses/new'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) => ref.read(recurringExpenseSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search recurring expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(recurringExpenseSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Choice chips for status filtering
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Active', 'Paused', 'Stopped'].map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: _statusFilter == status,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _statusFilter = status;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // List Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(recurringExpensesProvider.notifier).refresh(),
              child: expensesState.when(
                data: (list) {
                  final filteredList = _statusFilter == 'All'
                      ? list
                      : list.where((e) => e.status == _statusFilter).toList();

                  if (filteredList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.autorenew, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No recurring expenses found.',
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
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final exp = filteredList[index];
                      return _RecurringExpenseCard(expense: exp);
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
                          onPressed: () => ref.read(recurringExpensesProvider.notifier).refresh(),
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

class _RecurringExpenseCard extends ConsumerWidget {
  final RecurringExpense expense;

  const _RecurringExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startStr = DateFormat('dd MMM yyyy').format(expense.startDate);
    
    Color statusColor = AppColors.warning;
    if (expense.status == 'Active') {
      statusColor = AppColors.success;
    } else if (expense.status == 'Stopped') {
      statusColor = AppColors.danger;
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
                Expanded(
                  child: Text(
                    expense.expenseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: ${expense.category}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start: $startStr',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${expense.frequency} (Day ${expense.dueDay})',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Quick actions
                TextButton(
                  onPressed: () => context.push('/recurring-expenses/${expense.id}/edit'),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: AppSpacing.s),
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Recurring Expense'),
                          content: const Text('Are you sure you want to delete this recurring expense?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await ref.read(recurringExpensesProvider.notifier).deleteRecurringExpense(expense.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recurring expense deleted')),
                            );
                          }
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err.toString())),
                            );
                          }
                        }
                      }
                    } else {
                      try {
                        await ref.read(recurringExpensesProvider.notifier).updateStatus(expense.id, action);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Status updated to $action')),
                          );
                        }
                      } catch (err) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err.toString())),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (expense.status == 'Active')
                      const PopupMenuItem(value: 'pause', child: Text('Pause')),
                    if (expense.status == 'Paused')
                      const PopupMenuItem(value: 'resume', child: Text('Resume')),
                    if (expense.status != 'Stopped')
                      const PopupMenuItem(value: 'stop', child: Text('Stop')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
