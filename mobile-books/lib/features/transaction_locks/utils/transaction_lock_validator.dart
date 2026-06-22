import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/transaction_locks/data/models/transaction_lock.dart';
import 'package:mobile_books/features/transaction_locks/providers/transaction_lock_provider.dart';

enum TransactionLockModule {
  invoices('Invoices'),
  bills('Bills'),
  expenses('Expenses'),
  paymentsReceived('Payments Received'),
  paymentsMade('Payments Made'),
  manualJournals('Manual Journals'),
  bankTransactions('Bank Transactions'),
  creditNotes('Credit Notes'),
  vendorCredits('Vendor Credits');

  final String value;
  const TransactionLockModule(this.value);
}

class TransactionLockValidator {
  final TransactionLock? activeLock;

  TransactionLockValidator(this.activeLock);

  /// Checks if a given [module] is locked for transactions on or before [date].
  bool isLocked({required TransactionLockModule module, required DateTime date}) {
    final lock = activeLock;
    if (lock == null || !lock.isActive) return false;

    // Check if the module string matches any in the active lock modules list
    final hasModule = lock.lockedModules.any((m) => m.trim().toLowerCase() == module.value.trim().toLowerCase());
    if (!hasModule) return false;

    // Compare date parts only (truncate time components)
    final lockDateOnly = DateTime(lock.lockDate.year, lock.lockDate.month, lock.lockDate.day);
    final inputDateOnly = DateTime(date.year, date.month, date.day);

    // Return true if input date is on or before the lock date
    return inputDateOnly.isBefore(lockDateOnly) || inputDateOnly.isAtSameMomentAs(lockDateOnly);
  }
}

final transactionLockValidatorProvider = Provider<TransactionLockValidator>((ref) {
  final activeLockAsync = ref.watch(activeTransactionLockProvider);
  final activeLock = activeLockAsync.value;
  return TransactionLockValidator(activeLock);
});
