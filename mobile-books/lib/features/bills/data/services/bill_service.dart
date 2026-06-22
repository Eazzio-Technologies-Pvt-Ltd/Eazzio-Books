import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/bills/data/models/bill.dart';
import 'package:mobile_books/features/bills/data/models/bill_item.dart';

class BillException implements Exception {
  final String message;
  BillException(this.message);

  @override
  String toString() => message;
}

class BillDetails {
  final Bill bill;
  final List<BillItem> items;

  BillDetails({
    required this.bill,
    required this.items,
  });
}

class BillService {
  final NetworkClient _networkClient;

  BillService(this._networkClient);

  Future<List<Bill>> getBills() async {
    try {
      final response = await _networkClient.get('/bills');
      final data = response.data as Map<String, dynamic>;
      final list = data['bills'] as List? ?? [];
      return list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch bills.';
      throw BillException(message);
    } catch (e) {
      throw BillException(e.toString());
    }
  }

  Future<BillDetails> getBillById(int id) async {
    try {
      final response = await _networkClient.get('/bills/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['bill'] != null) {
        final bill = Bill.fromJson(data['bill'] as Map<String, dynamic>);
        final list = data['items'] as List? ?? [];
        final items = list.map((e) => BillItem.fromJson(e as Map<String, dynamic>)).toList();
        return BillDetails(bill: bill, items: items);
      } else {
        throw BillException('Invalid response structure for bill details.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch bill details.';
      throw BillException(message);
    } catch (e) {
      throw BillException(e.toString());
    }
  }

  Future<Bill> createBill(Bill bill, List<BillItem> items) async {
    try {
      final body = bill.toJson();
      body.remove('id');
      body['items'] = items.map((i) {
        final map = i.toJson();
        map.remove('id');
        map.remove('bill_id');
        return map;
      }).toList();

      final response = await _networkClient.post('/bills', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['bill'] != null) {
        return Bill.fromJson(data['bill'] as Map<String, dynamic>);
      } else {
        throw BillException('Invalid response structure for bill creation.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create bill.';
      throw BillException(message);
    } catch (e) {
      throw BillException(e.toString());
    }
  }

  Future<void> updateBill(int id, Map<String, dynamic> updates) async {
    try {
      await _networkClient.put('/bills/$id', data: updates);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update bill.';
      throw BillException(message);
    } catch (e) {
      throw BillException(e.toString());
    }
  }

  Future<void> deleteBill(int id) async {
    try {
      await _networkClient.delete('/bills/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete bill.';
      throw BillException(message);
    } catch (e) {
      throw BillException(e.toString());
    }
  }
}

final billServiceProvider = Provider<BillService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return BillService(networkClient);
});
