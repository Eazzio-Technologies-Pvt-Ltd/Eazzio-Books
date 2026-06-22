import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit_item.dart';

class VendorCreditException implements Exception {
  final String message;
  VendorCreditException(this.message);

  @override
  String toString() => message;
}

class VendorCreditDetails {
  final VendorCredit vendorCredit;
  final List<VendorCreditItem> items;

  VendorCreditDetails({
    required this.vendorCredit,
    required this.items,
  });
}

class VendorCreditService {
  final NetworkClient _networkClient;

  VendorCreditService(this._networkClient);

  Future<List<VendorCredit>> getVendorCredits() async {
    try {
      final response = await _networkClient.get('/vendor-credits');
      final data = response.data as Map<String, dynamic>;
      final list = data['vendor_credits'] as List? ?? [];
      return list.map((e) => VendorCredit.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch vendor credits.';
      throw VendorCreditException(message);
    } catch (e) {
      throw VendorCreditException(e.toString());
    }
  }

  Future<VendorCreditDetails> getVendorCreditById(int id) async {
    try {
      final response = await _networkClient.get('/vendor-credits/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['vendor_credit'] != null) {
        final vc = VendorCredit.fromJson(data['vendor_credit'] as Map<String, dynamic>);
        final list = data['items'] as List? ?? [];
        final items = list.map((e) => VendorCreditItem.fromJson(e as Map<String, dynamic>)).toList();
        return VendorCreditDetails(vendorCredit: vc, items: items);
      } else {
        throw VendorCreditException('Invalid response structure for vendor credit details.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch vendor credit details.';
      throw VendorCreditException(message);
    } catch (e) {
      throw VendorCreditException(e.toString());
    }
  }

  Future<VendorCredit> createVendorCredit(VendorCredit vc, List<VendorCreditItem> items) async {
    try {
      final body = vc.toJson();
      body.remove('id');
      body['items'] = items.map((i) {
        final map = i.toJson();
        map.remove('id');
        map.remove('vendor_credit_id');
        return map;
      }).toList();

      final response = await _networkClient.post('/vendor-credits', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['vendor_credit'] != null) {
        return VendorCredit.fromJson(data['vendor_credit'] as Map<String, dynamic>);
      } else {
        throw VendorCreditException('Invalid response structure for vendor credit creation.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create vendor credit.';
      throw VendorCreditException(message);
    } catch (e) {
      throw VendorCreditException(e.toString());
    }
  }

  Future<void> updateVendorCredit(int id, Map<String, dynamic> updates) async {
    try {
      await _networkClient.put('/vendor-credits/$id', data: updates);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update vendor credit.';
      throw VendorCreditException(message);
    } catch (e) {
      throw VendorCreditException(e.toString());
    }
  }

  Future<void> deleteVendorCredit(int id) async {
    try {
      await _networkClient.delete('/vendor-credits/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete vendor credit.';
      throw VendorCreditException(message);
    } catch (e) {
      throw VendorCreditException(e.toString());
    }
  }

  Future<void> sendEmail(int id, Map<String, dynamic> emailPayload) async {
    try {
      await _networkClient.post('/vendor-credits/$id/send', data: emailPayload);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to send vendor credit email.';
      throw VendorCreditException(message);
    } catch (e) {
      throw VendorCreditException(e.toString());
    }
  }

  Future<void> applyCredit(int id, int billId, double amount) async {
    try {
      await _networkClient.post('/vendor-credits/$id/apply', data: {
        'bill_id': billId,
        'amount': amount,
      });
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to apply vendor credit to bill.';
      throw VendorCreditException(message);
    } catch (e) {
      throw VendorCreditException(e.toString());
    }
  }
}

final vendorCreditServiceProvider = Provider<VendorCreditService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return VendorCreditService(networkClient);
});
