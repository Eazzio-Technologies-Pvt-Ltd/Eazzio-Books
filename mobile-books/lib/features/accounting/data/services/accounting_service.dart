import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/accounting/data/models/chart_of_account.dart';
import 'package:mobile_books/features/accounting/data/models/journal_entry.dart';

class AccountingException implements Exception {
  final String message;
  AccountingException(this.message);

  @override
  String toString() => message;
}

class AccountingService {
  final NetworkClient _networkClient;

  AccountingService(this._networkClient);

  // ================= CHART OF ACCOUNTS (COA) =================
  Future<List<ChartOfAccount>> getAccounts() async {
    try {
      final response = await _networkClient.get('/accounting/coa');
      final data = response.data as Map<String, dynamic>;
      final list = data['accounts'] as List? ?? [];
      return list.map((e) => ChartOfAccount.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch Chart of Accounts.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<ChartOfAccount> getAccountById(int id) async {
    try {
      final response = await _networkClient.get('/accounting/coa/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['account'] != null) {
        return ChartOfAccount.fromJson(data['account'] as Map<String, dynamic>);
      } else {
        throw AccountingException('Invalid account details response.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch account details.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<ChartOfAccount> createAccount(ChartOfAccount account) async {
    try {
      final body = account.toJson();
      body.remove('id'); // DB serial
      body.remove('current_balance'); // Initially set to opening_balance by backend
      final response = await _networkClient.post('/accounting/coa', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['account'] != null) {
        return ChartOfAccount.fromJson(data['account'] as Map<String, dynamic>);
      } else {
        throw AccountingException('Failed to parse created account.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create account.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<ChartOfAccount> updateAccount(int id, Map<String, dynamic> updates) async {
    try {
      // Backend update ignores opening_balance update (as defined in gaps register)
      final response = await _networkClient.put('/accounting/coa/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['account'] != null) {
        return ChartOfAccount.fromJson(data['account'] as Map<String, dynamic>);
      } else {
        throw AccountingException('Failed to parse updated account.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update account.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _networkClient.delete('/accounting/coa/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete account.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  // ================= MANUAL JOURNALS =================
  Future<List<JournalEntry>> getJournals() async {
    try {
      final response = await _networkClient.get('/accounting/journals');
      final data = response.data as Map<String, dynamic>;
      final list = data['journals'] as List? ?? [];
      return list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch manual journals.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<JournalEntry> getJournalById(int id) async {
    try {
      final response = await _networkClient.get('/accounting/journals/$id');
      final data = response.data as Map<String, dynamic>;
      final journalJson = data['journal'] as Map<String, dynamic>?;
      final linesJson = data['lines'] as List?;
      if (journalJson != null) {
        return JournalEntry.fromJson(journalJson, linesJson);
      } else {
        throw AccountingException('Invalid journal detail response.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch journal details.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<JournalEntry> createJournal(JournalEntry journal) async {
    try {
      final body = journal.toJson();
      body.remove('id'); // DB serial
      body.remove('total_debit'); // Calculated on backend
      body.remove('total_credit'); // Calculated on backend
      final response = await _networkClient.post('/accounting/journals', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['journal'] != null) {
        return JournalEntry.fromJson(data['journal'] as Map<String, dynamic>);
      } else {
        throw AccountingException('Failed to parse created journal entry.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create journal entry.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<JournalEntry> updateJournal(int id, JournalEntry journal) async {
    try {
      final body = journal.toJson();
      body.remove('id');
      body.remove('total_debit');
      body.remove('total_credit');
      final response = await _networkClient.put('/accounting/journals/$id', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['journal'] != null) {
        return JournalEntry.fromJson(data['journal'] as Map<String, dynamic>);
      } else {
        throw AccountingException('Failed to parse updated journal entry.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update journal entry.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }

  Future<void> deleteJournal(int id) async {
    try {
      await _networkClient.delete('/accounting/journals/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete journal entry.';
      throw AccountingException(message);
    } catch (e) {
      throw AccountingException(e.toString());
    }
  }
}

final accountingServiceProvider = Provider<AccountingService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return AccountingService(networkClient);
});
