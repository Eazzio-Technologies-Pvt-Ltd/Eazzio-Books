import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/transaction_locks/data/models/transaction_lock.dart';
import 'package:mobile_books/features/transaction_locks/data/services/transaction_lock_service.dart';

class ActiveTransactionLockNotifier extends AsyncNotifier<TransactionLock?> {
  @override
  Future<TransactionLock?> build() {
    return ref.watch(transactionLockServiceProvider).getActiveLock();
  }

  Future<TransactionLock> createTransactionLock({
    required String lockName,
    required DateTime lockDate,
    String? reason,
    required List<String> lockedModules,
  }) async {
    final service = ref.read(transactionLockServiceProvider);
    final result = await service.createTransactionLock(
      lockName: lockName,
      lockDate: lockDate,
      reason: reason,
      lockedModules: lockedModules,
    );
    ref.invalidateSelf();
    ref.invalidate(transactionLockHistoryProvider);
    return result;
  }

  Future<void> deactivateLock(int id) async {
    final service = ref.read(transactionLockServiceProvider);
    await service.deactivateLock(id);
    ref.invalidateSelf();
    ref.invalidate(transactionLockHistoryProvider);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final activeTransactionLockProvider = AsyncNotifierProvider<ActiveTransactionLockNotifier, TransactionLock?>(() {
  return ActiveTransactionLockNotifier();
});

class TransactionLockHistoryNotifier extends AsyncNotifier<List<TransactionLock>> {
  @override
  Future<List<TransactionLock>> build() {
    return ref.watch(transactionLockServiceProvider).getTransactionLocks();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final transactionLockHistoryProvider = AsyncNotifierProvider<TransactionLockHistoryNotifier, List<TransactionLock>>(() {
  return TransactionLockHistoryNotifier();
});
