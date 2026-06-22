import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/expenses/data/models/expense.dart';
import 'package:mobile_books/features/expenses/data/services/expense_service.dart';

class ExpenseSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final expenseSearchQueryProvider = NotifierProvider<ExpenseSearchQueryNotifier, String>(() {
  return ExpenseSearchQueryNotifier();
});

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() {
    return ref.watch(expenseServiceProvider).getExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(expenseServiceProvider).getExpenses();
    });
  }

  Future<Expense> createExpense(Expense expense) async {
    final service = ref.read(expenseServiceProvider);
    final result = await service.createExpense(expense);
    ref.invalidateSelf();
    return result;
  }

  Future<Expense> updateExpense(int id, Map<String, dynamic> updates) async {
    final service = ref.read(expenseServiceProvider);
    final result = await service.updateExpense(id, updates);
    ref.invalidateSelf();
    ref.invalidate(expenseDetailsProvider(id));
    return result;
  }

  Future<void> deleteExpense(int id) async {
    final service = ref.read(expenseServiceProvider);
    await service.deleteExpense(id);
    ref.invalidateSelf();
    ref.invalidate(expenseDetailsProvider(id));
  }

  Future<String> uploadReceipt(String filePath, String fileName) async {
    return ref.read(expenseServiceProvider).uploadReceipt(filePath, fileName);
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
  return ExpensesNotifier();
});

final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expState = ref.watch(expensesProvider);
  final searchQuery = ref.watch(expenseSearchQueryProvider).toLowerCase();

  return expState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((e) {
      final category = e.category.toLowerCase();
      final desc = (e.description ?? '').toLowerCase();
      final vendor = (e.vendorName ?? '').toLowerCase();
      final refNum = (e.reference ?? '').toLowerCase();
      return category.contains(searchQuery) ||
          desc.contains(searchQuery) ||
          vendor.contains(searchQuery) ||
          refNum.contains(searchQuery);
    }).toList();
  });
});

final expenseDetailsProvider = FutureProvider.family<Expense, int>((ref, id) {
  return ref.watch(expenseServiceProvider).getExpenseById(id);
});
