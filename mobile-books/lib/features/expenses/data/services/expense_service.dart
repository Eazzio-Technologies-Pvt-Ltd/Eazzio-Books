import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/expenses/data/models/expense.dart';

class ExpenseException implements Exception {
  final String message;
  ExpenseException(this.message);

  @override
  String toString() => message;
}

class ExpenseService {
  final NetworkClient _networkClient;

  ExpenseService(this._networkClient);

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _networkClient.get('/expenses');
      final data = response.data as Map<String, dynamic>;
      final list = data['expenses'] as List? ?? [];
      return list.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch expenses.';
      throw ExpenseException(message);
    } catch (e) {
      throw ExpenseException(e.toString());
    }
  }

  Future<Expense> getExpenseById(int id) async {
    try {
      final response = await _networkClient.get('/expenses/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['expense'] != null) {
        return Expense.fromJson(data['expense'] as Map<String, dynamic>);
      } else {
        throw ExpenseException('Invalid expense response structure.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch expense details.';
      throw ExpenseException(message);
    } catch (e) {
      throw ExpenseException(e.toString());
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    try {
      final body = expense.toJson();
      body.remove('id');
      final response = await _networkClient.post('/expenses', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['expense'] != null) {
        return Expense.fromJson(data['expense'] as Map<String, dynamic>);
      } else {
        throw ExpenseException('Invalid response structure for expense creation.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create expense.';
      throw ExpenseException(message);
    } catch (e) {
      throw ExpenseException(e.toString());
    }
  }

  Future<Expense> updateExpense(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/expenses/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['expense'] != null) {
        return Expense.fromJson(data['expense'] as Map<String, dynamic>);
      } else {
        throw ExpenseException('Invalid response structure for expense update.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update expense.';
      throw ExpenseException(message);
    } catch (e) {
      throw ExpenseException(e.toString());
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _networkClient.delete('/expenses/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete expense.';
      throw ExpenseException(message);
    } catch (e) {
      throw ExpenseException(e.toString());
    }
  }

  /// Uploads a receipt/attachment file via multipart form-data to the `/documents` endpoint.
  /// Returns the parsed `file_path` on the server to be used as `attachment_url` in the expense.
  Future<String> uploadReceipt(String filePath, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'document_name': fileName,
        'category': 'Receipt',
        'related_module': 'Expense',
      });
      final response = await _networkClient.post('/documents', data: formData);
      final data = response.data as Map<String, dynamic>;
      if (data['document'] != null && data['document']['file_path'] != null) {
        return data['document']['file_path'] as String;
      } else {
        throw ExpenseException('Invalid response structure from document service.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to upload receipt.';
      throw ExpenseException(message);
    } catch (e) {
      throw ExpenseException(e.toString());
    }
  }
}

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return ExpenseService(networkClient);
});
