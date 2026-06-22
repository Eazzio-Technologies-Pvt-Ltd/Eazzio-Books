import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/banking/data/models/bank_account.dart';
import 'package:mobile_books/features/banking/data/models/bank_transaction.dart';
import 'package:mobile_books/features/banking/data/models/bank_reconciliation.dart';

class BankingException implements Exception {
  final String message;
  BankingException(this.message);

  @override
  String toString() => message;
}

class BankingService {
  final NetworkClient _networkClient;

  BankingService(this._networkClient);

  Future<List<BankAccount>> getAccounts() async {
    try {
      final response = await _networkClient.get('/bank/accounts');
      final data = response.data as Map<String, dynamic>;
      final list = data['accounts'] as List? ?? [];
      return list.map((e) => BankAccount.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch bank accounts.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }

  Future<BankAccount> createAccount(BankAccount account) async {
    try {
      final body = account.toJson();
      body.remove('id'); // DB serial
      body.remove('current_balance'); // Calculated
      final response = await _networkClient.post('/bank/accounts', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['account'] != null) {
        return BankAccount.fromJson(data['account'] as Map<String, dynamic>);
      } else {
        throw BankingException('Failed to parse created bank account.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create bank account.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _networkClient.delete('/bank/accounts/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete bank account.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }

  Future<List<BankTransaction>> getTransactions(int accountId) async {
    try {
      final response = await _networkClient.get('/bank/accounts/$accountId/transactions');
      final data = response.data as Map<String, dynamic>;
      final list = data['transactions'] as List? ?? [];
      return list.map((e) => BankTransaction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch bank transactions.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }

  Future<BankTransaction> addTransaction(int accountId, BankTransaction transaction) async {
    try {
      final body = transaction.toJson();
      body.remove('id'); // DB serial
      body.remove('is_reconciled'); // Default is false
      body.remove('reconciled_at');
      final response = await _networkClient.post('/bank/accounts/$accountId/transactions', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['transaction'] != null) {
        return BankTransaction.fromJson(data['transaction'] as Map<String, dynamic>);
      } else {
        throw BankingException('Failed to parse recorded transaction.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to record bank transaction.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }

  Future<List<BankReconciliation>> getReconciliations(int bankAccountId) async {
    try {
      final response = await _networkClient.get('/bank/reconciliation/$bankAccountId');
      final data = response.data as Map<String, dynamic>;
      final list = data['reconciliations'] as List? ?? [];
      return list.map((e) => BankReconciliation.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch reconciliations.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }

  Future<BankReconciliation> createReconciliation(BankReconciliation reconciliation) async {
    try {
      final body = reconciliation.toJson();
      body.remove('id'); // DB serial
      final response = await _networkClient.post('/bank/reconciliation', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['reconciliation'] != null) {
        return BankReconciliation.fromJson(data['reconciliation'] as Map<String, dynamic>);
      } else {
        throw BankingException('Failed to parse saved reconciliation.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to save reconciliation statement.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }

  Future<void> reconcileBulkTransactions(List<int> transactionIds, bool isReconciled) async {
    try {
      await _networkClient.put(
        '/bank/transactions/reconcile-bulk',
        data: {
          'transaction_ids': transactionIds,
          'is_reconciled': isReconciled,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to bulk reconcile transactions.';
      throw BankingException(message);
    } catch (e) {
      throw BankingException(e.toString());
    }
  }
}

final bankingServiceProvider = Provider<BankingService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return BankingService(networkClient);
});
