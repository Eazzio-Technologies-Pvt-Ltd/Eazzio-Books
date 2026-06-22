import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan_item.dart';

class DeliveryChallanException implements Exception {
  final String message;
  DeliveryChallanException(this.message);

  @override
  String toString() => message;
}

class DeliveryChallanDetails {
  final DeliveryChallan deliveryChallan;
  final List<DeliveryChallanItem> items;

  DeliveryChallanDetails({
    required this.deliveryChallan,
    required this.items,
  });
}

class DeliveryChallanService {
  final NetworkClient _networkClient;

  DeliveryChallanService(this._networkClient);

  Future<List<DeliveryChallan>> getDeliveryChallans() async {
    try {
      final response = await _networkClient.get('/delivery-challans');
      final data = response.data as Map<String, dynamic>;
      final list = data['delivery_challans'] as List? ?? [];
      return list.map((e) => DeliveryChallan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch delivery challans.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<DeliveryChallanDetails> getDeliveryChallanById(int id) async {
    try {
      final response = await _networkClient.get('/delivery-challans/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['delivery_challan'] != null) {
        final deliveryChallan = DeliveryChallan.fromJson(data['delivery_challan'] as Map<String, dynamic>);
        final itemsList = data['items'] as List? ?? [];
        final items = itemsList.map((e) => DeliveryChallanItem.fromJson(e as Map<String, dynamic>)).toList();
        return DeliveryChallanDetails(deliveryChallan: deliveryChallan, items: items);
      } else {
        throw DeliveryChallanException('Invalid delivery challan response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch challan details.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<DeliveryChallan> createDeliveryChallan(DeliveryChallan dc, List<DeliveryChallanItem> items) async {
    try {
      final body = dc.toJson();
      body.remove('id');
      body['items'] = items.map((i) {
        final itemMap = i.toJson();
        itemMap.remove('id');
        itemMap.remove('delivery_challan_id');
        return itemMap;
      }).toList();

      final response = await _networkClient.post('/delivery-challans', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['delivery_challan'] != null) {
        return DeliveryChallan.fromJson(data['delivery_challan'] as Map<String, dynamic>);
      } else {
        throw DeliveryChallanException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create delivery challan.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<void> updateDeliveryChallan(int id, Map<String, dynamic> updates) async {
    try {
      await _networkClient.put('/delivery-challans/$id', data: updates);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update delivery challan.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<void> deleteDeliveryChallan(int id) async {
    try {
      await _networkClient.delete('/delivery-challans/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete delivery challan.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<DeliveryChallan> cancelDeliveryChallan(int id) async {
    try {
      final response = await _networkClient.patch('/delivery-challans/$id/cancel');
      final data = response.data as Map<String, dynamic>;
      if (data['delivery_challan'] != null) {
        return DeliveryChallan.fromJson(data['delivery_challan'] as Map<String, dynamic>);
      } else {
        throw DeliveryChallanException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to cancel delivery challan.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<DeliveryChallan> markDelivered(int id) async {
    try {
      final response = await _networkClient.patch('/delivery-challans/$id/mark-delivered');
      final data = response.data as Map<String, dynamic>;
      if (data['delivery_challan'] != null) {
        return DeliveryChallan.fromJson(data['delivery_challan'] as Map<String, dynamic>);
      } else {
        throw DeliveryChallanException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to mark delivery challan as delivered.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<int> convertFromSalesOrder(int salesOrderId) async {
    try {
      final response = await _networkClient.post('/delivery-challans/from-sales-order/$salesOrderId');
      final data = response.data as Map<String, dynamic>;
      final dcId = data['deliveryChallanId'] as int?;
      if (dcId != null) {
        return dcId;
      } else {
        throw DeliveryChallanException('Could not resolve delivery challan ID from server response.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to convert from Sales Order.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<int> convertDeliveryChallanToInvoice(int id) async {
    try {
      final response = await _networkClient.post('/delivery-challans/$id/convert-to-invoice');
      final data = response.data as Map<String, dynamic>;
      final invoiceId = data['invoiceId'] as int?;
      if (invoiceId != null) {
        return invoiceId;
      } else {
        throw DeliveryChallanException('Could not resolve invoice ID from server response.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to convert delivery challan to invoice.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }

  Future<void> sendDeliveryChallanEmail(int id, Map<String, dynamic> emailPayload) async {
    try {
      await _networkClient.post('/delivery-challans/$id/send', data: emailPayload);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to send delivery challan email.';
      throw DeliveryChallanException(message);
    } catch (e) {
      throw DeliveryChallanException(e.toString());
    }
  }
}

final deliveryChallanServiceProvider = Provider<DeliveryChallanService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return DeliveryChallanService(networkClient);
});
