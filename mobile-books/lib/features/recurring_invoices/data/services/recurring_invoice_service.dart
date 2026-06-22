import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice_item.dart';

class RecurringInvoiceException implements Exception {
  final String message;
  RecurringInvoiceException(this.message);

  @override
  String toString() => message;
}

class RecurringInvoiceService {
  final NetworkClient _networkClient;

  RecurringInvoiceService(this._networkClient);

  Future<List<RecurringInvoice>> getRecurringInvoices() async {
    try {
      final response = await _networkClient.get('/recurring-invoices');
      final data = response.data as Map<String, dynamic>;
      final list = data['recurring_invoices'] as List? ?? [];
      return list.map((e) => RecurringInvoice.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch recurring invoices.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<RecurringInvoice> getRecurringInvoiceById(int id) async {
    try {
      final response = await _networkClient.get('/recurring-invoices/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['recurring_invoice'] != null) {
        return RecurringInvoice.fromJson(data['recurring_invoice'] as Map<String, dynamic>);
      } else {
        throw RecurringInvoiceException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch recurring invoice.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<int> createRecurringInvoice(RecurringInvoice ri, List<RecurringInvoiceItem> items) async {
    try {
      final body = ri.toJson();
      body.remove('id');
      body['items'] = items.map((i) {
        final itemMap = i.toJson();
        itemMap.remove('id');
        itemMap.remove('recurring_invoice_id');
        return itemMap;
      }).toList();

      final response = await _networkClient.post('/recurring-invoices', data: body);
      final data = response.data as Map<String, dynamic>;
      final newId = data['id'] as int?;
      if (newId != null) {
        return newId;
      } else {
        throw RecurringInvoiceException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create recurring invoice.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<void> updateRecurringInvoice(int id, Map<String, dynamic> updates) async {
    try {
      await _networkClient.put('/recurring-invoices/$id', data: updates);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update recurring invoice.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<void> pauseRecurringInvoice(int id) async {
    try {
      await _networkClient.patch('/recurring-invoices/$id/pause');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to pause recurring invoice.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<void> resumeRecurringInvoice(int id) async {
    try {
      await _networkClient.patch('/recurring-invoices/$id/resume');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to resume recurring invoice.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<void> stopRecurringInvoice(int id) async {
    try {
      await _networkClient.patch('/recurring-invoices/$id/stop');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to stop recurring invoice.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<int> generateNow(int id) async {
    try {
      final response = await _networkClient.post('/recurring-invoices/$id/generate-now');
      final data = response.data as Map<String, dynamic>;
      final invId = data['invoice_id'] as int?;
      if (invId != null) {
        return invId;
      } else {
        throw RecurringInvoiceException('Failed to generate invoice.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to trigger manual generation.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }

  Future<List<Invoice>> getGeneratedInvoices(int id) async {
    try {
      final response = await _networkClient.get('/recurring-invoices/$id/generated-invoices');
      final data = response.data as Map<String, dynamic>;
      final list = data['invoices'] as List? ?? [];
      return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch generated invoices list.';
      throw RecurringInvoiceException(message);
    } catch (e) {
      throw RecurringInvoiceException(e.toString());
    }
  }
}

final recurringInvoiceServiceProvider = Provider<RecurringInvoiceService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return RecurringInvoiceService(networkClient);
});
