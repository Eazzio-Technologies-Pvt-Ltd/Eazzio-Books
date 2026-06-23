import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order_item.dart';

class SalesOrderException implements Exception {
  final String message;
  SalesOrderException(this.message);

  @override
  String toString() => message;
}

class SalesOrderDetails {
  final SalesOrder salesOrder;
  final List<SalesOrderItem> items;

  SalesOrderDetails({
    required this.salesOrder,
    required this.items,
  });
}

class SalesOrderService {
  final NetworkClient _networkClient;

  SalesOrderService(this._networkClient);

  /// Fetches all sales orders
  Future<List<SalesOrder>> getSalesOrders() async {
    try {
      final response = await _networkClient.get('/sales-orders');
      final data = response.data as Map<String, dynamic>;
      final list = data['sales_orders'] as List? ?? [];
      return list.map((e) => SalesOrder.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch sales orders.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Fetches details for a single sales order
  Future<SalesOrderDetails> getSalesOrderById(int id) async {
    try {
      final response = await _networkClient.get('/sales-orders/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['sales_order'] != null) {
        final salesOrder = SalesOrder.fromJson(data['sales_order'] as Map<String, dynamic>);
        final itemsList = data['items'] as List? ?? [];
        final items = itemsList.map((e) => SalesOrderItem.fromJson(e as Map<String, dynamic>)).toList();
        return SalesOrderDetails(salesOrder: salesOrder, items: items);
      } else {
        throw SalesOrderException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch sales order details.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Creates a new sales order with items
  Future<SalesOrder> createSalesOrder(SalesOrder order, List<SalesOrderItem> items) async {
    try {
      final body = order.toJson();
      body.remove('id');
      body['items'] = items.map((i) {
        final itemMap = i.toJson();
        itemMap.remove('id');
        itemMap.remove('sales_order_id');
        return itemMap;
      }).toList();

      final response = await _networkClient.post('/sales-orders', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['sales_order'] != null) {
        return SalesOrder.fromJson(data['sales_order'] as Map<String, dynamic>);
      } else {
        throw SalesOrderException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create sales order.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Updates an existing sales order
  Future<SalesOrder> updateSalesOrder(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/sales-orders/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['sales_order'] != null) {
        return SalesOrder.fromJson(data['sales_order'] as Map<String, dynamic>);
      } else {
        throw SalesOrderException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update sales order.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Deletes a sales order by ID
  Future<void> deleteSalesOrder(int id) async {
    try {
      await _networkClient.delete('/sales-orders/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete sales order.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Converts a quote to a sales order
  Future<SalesOrder> convertQuoteToSalesOrder(int quoteId) async {
    try {
      final response = await _networkClient.post('/sales-orders/from-quote/$quoteId');
      final data = response.data as Map<String, dynamic>;
      if (data['sales_order'] != null) {
        return SalesOrder.fromJson(data['sales_order'] as Map<String, dynamic>);
      } else {
        throw SalesOrderException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to convert quote to sales order.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Converts a sales order to an invoice
  Future<Map<String, dynamic>> convertSalesOrderToInvoice(int id) async {
    try {
      final response = await _networkClient.post('/sales-orders/$id/convert-to-invoice');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to convert sales order to invoice.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Sends a sales order statement via email
  Future<void> sendSalesOrderEmail(int id, Map<String, dynamic> emailPayload) async {
    try {
      await _networkClient.post('/sales-orders/$id/send', data: emailPayload);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to send sales order email.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }

  /// Marks a sales order as sent/confirmed in backend
  Future<void> markSalesOrderAsSent(int id) async {
    try {
      await _networkClient.patch('/sales-orders/$id/mark-sent');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to mark sales order as sent.';
      throw SalesOrderException(message);
    } catch (e) {
      throw SalesOrderException(e.toString());
    }
  }
}

final salesOrderServiceProvider = Provider<SalesOrderService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return SalesOrderService(networkClient);
});
