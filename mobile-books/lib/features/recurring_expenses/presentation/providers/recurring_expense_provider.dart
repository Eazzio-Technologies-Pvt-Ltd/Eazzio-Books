import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/recurring_expenses/data/models/recurring_expense.dart';
import 'package:mobile_books/features/recurring_expenses/data/services/recurring_expense_service.dart';

class RecurringExpenseSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final recurringExpenseSearchQueryProvider = NotifierProvider<RecurringExpenseSearchQueryNotifier, String>(() {
  return RecurringExpenseSearchQueryNotifier();
});

class RecurringExpensesNotifier extends AsyncNotifier<List<RecurringExpense>> {
  @override
  Future<List<RecurringExpense>> build() {
    return ref.watch(recurringExpenseServiceProvider).getRecurringExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(recurringExpenseServiceProvider).getRecurringExpenses();
    });
  }

  Future<RecurringExpense> createRecurringExpense(RecurringExpense expense) async {
    final service = ref.read(recurringExpenseServiceProvider);
    final result = await service.createRecurringExpense(expense);
    ref.invalidateSelf();
    return result;
  }

  Future<RecurringExpense> updateRecurringExpense(int id, RecurringExpense expense) async {
    final service = ref.read(recurringExpenseServiceProvider);
    final result = await service.updateRecurringExpense(id, expense);
    ref.invalidateSelf();
    ref.invalidate(recurringExpenseDetailsProvider(id));
    return result;
  }

  Future<void> deleteRecurringExpense(int id) async {
    final service = ref.read(recurringExpenseServiceProvider);
    await service.deleteRecurringExpense(id);
    ref.invalidateSelf();
    ref.invalidate(recurringExpenseDetailsProvider(id));
  }

  Future<RecurringExpense> updateStatus(int id, String action) async {
    final service = ref.read(recurringExpenseServiceProvider);
    final result = await service.updateStatus(id, action);
    ref.invalidateSelf();
    ref.invalidate(recurringExpenseDetailsProvider(id));
    return result;
  }
}

final recurringExpensesProvider = AsyncNotifierProvider<RecurringExpensesNotifier, List<RecurringExpense>>(() {
  return RecurringExpensesNotifier();
});

final filteredRecurringExpensesProvider = Provider<AsyncValue<List<RecurringExpense>>>((ref) {
  final expState = ref.watch(recurringExpensesProvider);
  final searchQuery = ref.watch(recurringExpenseSearchQueryProvider).toLowerCase();

  return expState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((e) {
      final name = e.expenseName.toLowerCase();
      final category = e.category.toLowerCase();
      final notes = (e.notes ?? '').toLowerCase();
      return name.contains(searchQuery) ||
          category.contains(searchQuery) ||
          notes.contains(searchQuery);
    }).toList();
  });
});

final recurringExpenseDetailsProvider = FutureProvider.family<RecurringExpense, int>((ref, id) {
  return ref.watch(recurringExpenseServiceProvider).getRecurringExpenseById(id);
});
