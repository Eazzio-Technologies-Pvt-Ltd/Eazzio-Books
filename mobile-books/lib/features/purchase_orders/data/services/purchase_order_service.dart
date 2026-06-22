import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/purchase_orders/data/models/purchase_order.dart';
import 'package:mobile_books/features/purchase_orders/data/models/purchase_order_item.dart';

class PurchaseOrderException implements Exception {
  final String message;
  PurchaseOrderException(this.message);

  @override
  String toString() => message;
}

class PurchaseOrderDetails {
  final PurchaseOrder purchaseOrder;
  final List<PurchaseOrderItem> items;

  PurchaseOrderDetails({
    required this.purchaseOrder,
    required this.items,
  });
}

class PurchaseOrderService {
  final NetworkClient _networkClient;

  PurchaseOrderService(this._networkClient);

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    try {
      final response = await _networkClient.get('/purchase-orders');
      final data = response.data as Map<String, dynamic>;
      final list = data['purchase_orders'] as List? ?? [];
      return list.map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch purchase orders.';
      throw PurchaseOrderException(message);
    } catch (e) {
      throw PurchaseOrderException(e.toString());
    }
  }

  Future<PurchaseOrderDetails> getPurchaseOrderById(int id) async {
    try {
      final response = await _networkClient.get('/purchase-orders/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['purchase_order'] != null) {
        final po = PurchaseOrder.fromJson(data['purchase_order'] as Map<String, dynamic>);
        final list = data['items'] as List? ?? [];
        final items = list.map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>)).toList();
        return PurchaseOrderDetails(purchaseOrder: po, items: items);
      } else {
        throw PurchaseOrderException('Invalid response structure for purchase order details.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch purchase order details.';
      throw PurchaseOrderException(message);
    } catch (e) {
      throw PurchaseOrderException(e.toString());
    }
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po, List<PurchaseOrderItem> items) async {
    try {
      final body = po.toJson();
      body.remove('id');
      body['items'] = items.map((i) {
        final map = i.toJson();
        map.remove('id');
        map.remove('purchase_order_id');
        return map;
      }).toList();

      final response = await _networkClient.post('/purchase-orders', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['purchase_order'] != null) {
        return PurchaseOrder.fromJson(data['purchase_order'] as Map<String, dynamic>);
      } else {
        throw PurchaseOrderException('Invalid response structure for purchase order creation.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create purchase order.';
      throw PurchaseOrderException(message);
    } catch (e) {
      throw PurchaseOrderException(e.toString());
    }
  }

  Future<void> updatePurchaseOrder(int id, Map<String, dynamic> updates) async {
    try {
      await _networkClient.put('/purchase-orders/$id', data: updates);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update purchase order.';
      throw PurchaseOrderException(message);
    } catch (e) {
      throw PurchaseOrderException(e.toString());
    }
  }

  Future<void> deletePurchaseOrder(int id) async {
    try {
      await _networkClient.delete('/purchase-orders/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete purchase order.';
      throw PurchaseOrderException(message);
    } catch (e) {
      throw PurchaseOrderException(e.toString());
    }
  }

  Future<void> sendEmail(int id, Map<String, dynamic> emailPayload) async {
    try {
      await _networkClient.post('/purchase-orders/$id/send', data: emailPayload);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to send purchase order email.';
      throw PurchaseOrderException(message);
    } catch (e) {
      throw PurchaseOrderException(e.toString());
    }
  }

  Future<int> convertToBill(int id) async {
    try {
      final response = await _networkClient.post('/purchase-orders/$id/convert-to-bill');
      final data = response.data as Map<String, dynamic>;
      final billId = data['billId'] as int?;
      if (billId != null) {
        return billId;
      } else {
        throw PurchaseOrderException('Could not resolve bill ID from conversion response.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to convert to Bill.';
      throw PurchaseOrderException(message);
    } catch (e) {
      throw PurchaseOrderException(e.toString());
    }
  }
}

final purchaseOrderServiceProvider = Provider<PurchaseOrderService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return PurchaseOrderService(networkClient);
});
