import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/transaction_locks/data/models/transaction_lock.dart';
import 'package:mobile_books/features/transaction_locks/data/services/transaction_lock_service.dart';

class TransactionLockRepository {
  final TransactionLockService _service;

  TransactionLockRepository(this._service);

  Future<List<TransactionLock>> getTransactionLocks() {
    return _service.getTransactionLocks();
  }

  Future<TransactionLock?> getActiveLock() {
    return _service.getActiveLock();
  }

  Future<TransactionLock> createTransactionLock({
    required String lockName,
    required DateTime lockDate,
    String? reason,
    required List<String> lockedModules,
  }) {
    return _service.createTransactionLock(
      lockName: lockName,
      lockDate: lockDate,
      reason: reason,
      lockedModules: lockedModules,
    );
  }

  Future<void> deactivateLock(int id) {
    return _service.deactivateLock(id);
  }
}

final transactionLockRepositoryProvider = Provider<TransactionLockRepository>((ref) {
  final service = ref.watch(transactionLockServiceProvider);
  return TransactionLockRepository(service);
});
