import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/accounting/data/models/chart_of_account.dart';
import 'package:mobile_books/features/accounting/data/models/journal_entry.dart';
import 'package:mobile_books/features/accounting/data/services/accounting_service.dart';

class CoaAccountsNotifier extends AsyncNotifier<List<ChartOfAccount>> {
  @override
  Future<List<ChartOfAccount>> build() {
    return ref.watch(accountingServiceProvider).getAccounts();
  }

  Future<ChartOfAccount> createAccount(ChartOfAccount account) async {
    final service = ref.read(accountingServiceProvider);
    final result = await service.createAccount(account);
    ref.invalidateSelf();
    return result;
  }

  Future<ChartOfAccount> updateAccount(int id, Map<String, dynamic> updates) async {
    final service = ref.read(accountingServiceProvider);
    final result = await service.updateAccount(id, updates);
    ref.invalidateSelf();
    ref.invalidate(coaAccountDetailsProvider(id));
    return result;
  }

  Future<void> deleteAccount(int id) async {
    final service = ref.read(accountingServiceProvider);
    await service.deleteAccount(id);
    ref.invalidateSelf();
    ref.invalidate(coaAccountDetailsProvider(id));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final coaAccountsProvider = AsyncNotifierProvider<CoaAccountsNotifier, List<ChartOfAccount>>(() {
  return CoaAccountsNotifier();
});

final coaAccountDetailsProvider = FutureProvider.family<ChartOfAccount, int>((ref, id) {
  return ref.watch(accountingServiceProvider).getAccountById(id);
});

class JournalsNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() {
    return ref.watch(accountingServiceProvider).getJournals();
  }

  Future<JournalEntry> createJournal(JournalEntry journal) async {
    final service = ref.read(accountingServiceProvider);
    final result = await service.createJournal(journal);
    ref.invalidateSelf();
    return result;
  }

  Future<JournalEntry> updateJournal(int id, JournalEntry journal) async {
    final service = ref.read(accountingServiceProvider);
    final result = await service.updateJournal(id, journal);
    ref.invalidateSelf();
    ref.invalidate(journalDetailsProvider(id));
    return result;
  }

  Future<void> deleteJournal(int id) async {
    final service = ref.read(accountingServiceProvider);
    await service.deleteJournal(id);
    ref.invalidateSelf();
    ref.invalidate(journalDetailsProvider(id));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final journalsProvider = AsyncNotifierProvider<JournalsNotifier, List<JournalEntry>>(() {
  return JournalsNotifier();
});

final journalDetailsProvider = FutureProvider.family<JournalEntry, int>((ref, id) {
  return ref.watch(accountingServiceProvider).getJournalById(id);
});
