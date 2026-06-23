import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/invoices/data/models/invoice_item.dart';
import 'package:mobile_books/features/invoices/data/models/payment.dart';

class InvoiceException implements Exception {
  final String message;
  InvoiceException(this.message);

  @override
  String toString() => message;
}

class InvoiceDetails {
  final Invoice invoice;
  final List<InvoiceItem> items;

  InvoiceDetails({
    required this.invoice,
    required this.items,
  });
}

class InvoiceService {
  final NetworkClient _networkClient;

  InvoiceService(this._networkClient);

  /// Fetches all invoices belonging to the active tenant/organization
  Future<List<Invoice>> getInvoices() async {
    try {
      final response = await _networkClient.get('/invoices');
      final data = response.data as Map<String, dynamic>;
      final list = data['invoices'] as List? ?? [];
      return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch invoices list.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Fetches invoice details and items for a single invoice ID
  Future<InvoiceDetails> getInvoiceById(int id) async {
    try {
      final response = await _networkClient.get('/invoices/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['invoice'] != null) {
        final invoice = Invoice.fromJson(data['invoice'] as Map<String, dynamic>);
        final itemsList = data['items'] as List? ?? [];
        final items = itemsList.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList();
        return InvoiceDetails(invoice: invoice, items: items);
      } else {
        throw InvoiceException('Invalid invoice response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch invoice details.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Creates a new invoice with associated line items
  Future<Invoice> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final body = invoice.toJson();
      body.remove('id'); // generated on backend
      body['items'] = items.map((i) {
        final itemMap = i.toJson();
        itemMap.remove('id');
        itemMap.remove('invoice_id');
        return itemMap;
      }).toList();

      final response = await _networkClient.post('/invoices', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['invoice'] != null) {
        return Invoice.fromJson(data['invoice'] as Map<String, dynamic>);
      } else {
        throw InvoiceException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create invoice.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Updates details/items of an existing invoice
  Future<void> updateInvoice(int id, Map<String, dynamic> updates) async {
    try {
      await _networkClient.put('/invoices/$id', data: updates);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update invoice.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Deletes an invoice by ID
  Future<void> deleteInvoice(int id) async {
    try {
      await _networkClient.delete('/invoices/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete invoice.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Sends the invoice statement/PDF via email SMTP relay
  Future<void> sendEmail(int id, {
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      await _networkClient.post(
        '/invoices/$id/send',
        data: {'to': to, 'subject': subject, 'body': body},
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to send invoice email.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Downloads invoice statement PDF bytes
  Future<Uint8List> downloadInvoicePDF(int id) async {
    try {
      final response = await _networkClient.get(
        '/invoices/$id/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to download PDF.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Get the direct download URL for Invoice PDF
  String getInvoicePdfUrl(int id) {
    return '${_networkClient.dio.options.baseUrl}/invoices/$id/pdf';
  }

  /// Records a payment against an invoice
  Future<double> recordPayment(int id, Map<String, dynamic> paymentPayload) async {
    try {
      final response = await _networkClient.post('/invoices/$id/payments', data: paymentPayload);
      final data = response.data as Map<String, dynamic>;
      final newBalance = data['newBalanceDue'] as num? ?? data['new_balance_due'] as num? ?? 0.0;
      return newBalance.toDouble();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to record payment.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Fetches all recorded payments for an invoice
  Future<List<Payment>> getPayments(int id) async {
    try {
      final response = await _networkClient.get('/invoices/$id/payments');
      final data = response.data as Map<String, dynamic>;
      final list = data['payments'] as List? ?? [];
      return list.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch payments list.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Fetches all payments received across all invoices
  Future<List<Payment>> getAllPayments() async {
    try {
      final response = await _networkClient.get('/payments');
      final data = response.data as Map<String, dynamic>;
      final list = data['payments'] as List? ?? [];
      return list.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch all payments.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }

  /// Marks an invoice as sent in backend
  Future<void> markInvoiceAsSent(int id) async {
    try {
      await _networkClient.patch('/invoices/$id/mark-sent');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to mark invoice as sent.';
      throw InvoiceException(message);
    } catch (e) {
      throw InvoiceException(e.toString());
    }
  }
}

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return InvoiceService(networkClient);
});
