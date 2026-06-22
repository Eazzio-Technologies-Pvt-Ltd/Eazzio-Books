import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/recurring_expenses/data/models/recurring_expense.dart';

class RecurringExpenseException implements Exception {
  final String message;
  RecurringExpenseException(this.message);

  @override
  String toString() => message;
}

class RecurringExpenseService {
  final NetworkClient _networkClient;

  RecurringExpenseService(this._networkClient);

  Future<List<RecurringExpense>> getRecurringExpenses() async {
    try {
      final response = await _networkClient.get('/recurring-expenses');
      final data = response.data as Map<String, dynamic>;
      final list = data['recurringExpenses'] as List? ?? [];
      return list.map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch recurring expenses.';
      throw RecurringExpenseException(message);
    } catch (e) {
      throw RecurringExpenseException(e.toString());
    }
  }

  Future<RecurringExpense> getRecurringExpenseById(int id) async {
    try {
      final response = await _networkClient.get('/recurring-expenses/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['recurringExpense'] != null) {
        return RecurringExpense.fromJson(data['recurringExpense'] as Map<String, dynamic>);
      } else {
        throw RecurringExpenseException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch recurring expense details.';
      throw RecurringExpenseException(message);
    } catch (e) {
      throw RecurringExpenseException(e.toString());
    }
  }

  Future<RecurringExpense> createRecurringExpense(RecurringExpense expense) async {
    try {
      final body = expense.toJson();
      body.remove('id');
      body.remove('created_by');
      final response = await _networkClient.post('/recurring-expenses', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['recurringExpense'] != null) {
        return RecurringExpense.fromJson(data['recurringExpense'] as Map<String, dynamic>);
      } else {
        throw RecurringExpenseException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create recurring expense.';
      throw RecurringExpenseException(message);
    } catch (e) {
      throw RecurringExpenseException(e.toString());
    }
  }

  Future<RecurringExpense> updateRecurringExpense(int id, RecurringExpense expense) async {
    try {
      final body = expense.toJson();
      body.remove('id');
      body.remove('created_by');
      final response = await _networkClient.put('/recurring-expenses/$id', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['recurringExpense'] != null) {
        return RecurringExpense.fromJson(data['recurringExpense'] as Map<String, dynamic>);
      } else {
        throw RecurringExpenseException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update recurring expense.';
      throw RecurringExpenseException(message);
    } catch (e) {
      throw RecurringExpenseException(e.toString());
    }
  }

  Future<void> deleteRecurringExpense(int id) async {
    try {
      await _networkClient.delete('/recurring-expenses/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete recurring expense.';
      throw RecurringExpenseException(message);
    } catch (e) {
      throw RecurringExpenseException(e.toString());
    }
  }

  Future<RecurringExpense> updateStatus(int id, String action) async {
    // action is 'pause', 'resume', or 'stop'
    try {
      final response = await _networkClient.patch('/recurring-expenses/$id/$action');
      final data = response.data as Map<String, dynamic>;
      if (data['recurringExpense'] != null) {
        return RecurringExpense.fromJson(data['recurringExpense'] as Map<String, dynamic>);
      } else {
        throw RecurringExpenseException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update recurring expense status.';
      throw RecurringExpenseException(message);
    } catch (e) {
      throw RecurringExpenseException(e.toString());
    }
  }
}

final recurringExpenseServiceProvider = Provider<RecurringExpenseService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return RecurringExpenseService(networkClient);
});
