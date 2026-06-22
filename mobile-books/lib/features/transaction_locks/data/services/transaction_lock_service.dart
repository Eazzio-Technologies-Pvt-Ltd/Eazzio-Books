import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/transaction_locks/data/models/transaction_lock.dart';

class TransactionLockException implements Exception {
  final String message;
  TransactionLockException(this.message);

  @override
  String toString() => message;
}

class TransactionLockService {
  final NetworkClient _networkClient;

  TransactionLockService(this._networkClient);

  Future<List<TransactionLock>> getTransactionLocks() async {
    try {
      final response = await _networkClient.get('/transaction-locks');
      final data = response.data as Map<String, dynamic>;
      final list = data['locks'] as List? ?? [];
      return list.map((e) => TransactionLock.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch transaction locks.';
      throw TransactionLockException(message);
    } catch (e) {
      throw TransactionLockException(e.toString());
    }
  }

  Future<TransactionLock?> getActiveLock() async {
    try {
      final response = await _networkClient.get('/transaction-locks/active');
      final data = response.data as Map<String, dynamic>;
      if (data['lock'] != null) {
        return TransactionLock.fromJson(data['lock'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch active transaction lock.';
      throw TransactionLockException(message);
    } catch (e) {
      throw TransactionLockException(e.toString());
    }
  }

  Future<TransactionLock> createTransactionLock({
    required String lockName,
    required DateTime lockDate,
    String? reason,
    required List<String> lockedModules,
  }) async {
    try {
      final body = {
        'lock_name': lockName,
        'lock_date': lockDate.toIso8601String().split('T')[0],
        'reason': reason,
        'locked_modules': lockedModules,
      };
      final response = await _networkClient.post('/transaction-locks', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['lock'] != null) {
        return TransactionLock.fromJson(data['lock'] as Map<String, dynamic>);
      } else {
        throw TransactionLockException('Failed to parse created lock.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create transaction lock.';
      throw TransactionLockException(message);
    } catch (e) {
      throw TransactionLockException(e.toString());
    }
  }

  Future<void> deactivateLock(int id) async {
    try {
      await _networkClient.patch('/transaction-locks/$id/deactivate');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to deactivate transaction lock.';
      throw TransactionLockException(message);
    } catch (e) {
      throw TransactionLockException(e.toString());
    }
  }
}

final transactionLockServiceProvider = Provider<TransactionLockService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return TransactionLockService(networkClient);
});
