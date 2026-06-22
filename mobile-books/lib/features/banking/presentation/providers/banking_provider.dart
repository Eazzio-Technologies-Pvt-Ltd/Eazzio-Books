import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/banking/data/models/bank_account.dart';
import 'package:mobile_books/features/banking/data/models/bank_transaction.dart';
import 'package:mobile_books/features/banking/data/models/bank_reconciliation.dart';
import 'package:mobile_books/features/banking/data/services/banking_service.dart';

class BankAccountsNotifier extends AsyncNotifier<List<BankAccount>> {
  @override
  Future<List<BankAccount>> build() {
    return ref.watch(bankingServiceProvider).getAccounts();
  }

  Future<BankAccount> createAccount(BankAccount account) async {
    final service = ref.read(bankingServiceProvider);
    final result = await service.createAccount(account);
    ref.invalidateSelf();
    return result;
  }

  Future<void> deleteAccount(int id) async {
    final service = ref.read(bankingServiceProvider);
    await service.deleteAccount(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final bankAccountsProvider = AsyncNotifierProvider<BankAccountsNotifier, List<BankAccount>>(() {
  return BankAccountsNotifier();
});

final bankTransactionsProvider = FutureProvider.family<List<BankTransaction>, int>((ref, accountId) {
  return ref.watch(bankingServiceProvider).getTransactions(accountId);
});

final bankReconciliationsProvider = FutureProvider.family<List<BankReconciliation>, int>((ref, bankAccountId) {
  return ref.watch(bankingServiceProvider).getReconciliations(bankAccountId);
});

class BankingOperationsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<BankTransaction> addTransaction(int accountId, BankTransaction transaction) async {
    final service = ref.read(bankingServiceProvider);
    final result = await service.addTransaction(accountId, transaction);
    
    // Invalidate transactions list for this account
    ref.invalidate(bankTransactionsProvider(accountId));
    // Invalidate accounts list to update current balance
    ref.invalidate(bankAccountsProvider);
    return result;
  }

  Future<void> reconcileBulkTransactions(int accountId, List<int> transactionIds, bool isReconciled) async {
    final service = ref.read(bankingServiceProvider);
    await service.reconcileBulkTransactions(transactionIds, isReconciled);
    
    // Invalidate transactions to show updated reconciled checkmarks
    ref.invalidate(bankTransactionsProvider(accountId));
  }

  Future<BankReconciliation> createReconciliation(BankReconciliation reconciliation) async {
    final service = ref.read(bankingServiceProvider);
    final result = await service.createReconciliation(reconciliation);
    
    // Invalidate reconciliation list
    ref.invalidate(bankReconciliationsProvider(reconciliation.bankAccountId));
    return result;
  }
}

final bankingOperationsProvider = NotifierProvider<BankingOperationsNotifier, void>(() {
  return BankingOperationsNotifier();
});

class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Default: show financial values
  }

  void toggle() {
    state = !state;
  }
}

final privacyModeProvider = NotifierProvider<PrivacyModeNotifier, bool>(() {
  return PrivacyModeNotifier();
});
