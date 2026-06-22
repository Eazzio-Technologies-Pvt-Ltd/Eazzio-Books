import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/payments_made/data/models/payment_made.dart';

class PaymentMadeException implements Exception {
  final String message;
  PaymentMadeException(this.message);

  @override
  String toString() => message;
}

class PaymentMadeService {
  final NetworkClient _networkClient;

  PaymentMadeService(this._networkClient);

  Future<List<PaymentMade>> getPaymentsMade() async {
    try {
      final response = await _networkClient.get('/payments-made');
      final data = response.data as Map<String, dynamic>;
      final list = data['payments'] as List? ?? [];
      return list.map((e) => PaymentMade.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch payments made.';
      throw PaymentMadeException(message);
    } catch (e) {
      throw PaymentMadeException(e.toString());
    }
  }

  Future<PaymentMade> getPaymentMadeById(int id) async {
    try {
      final response = await _networkClient.get('/payments-made/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['payment'] != null) {
        return PaymentMade.fromJson(data['payment'] as Map<String, dynamic>);
      } else {
        throw PaymentMadeException('Invalid response structure for payment details.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch payment details.';
      throw PaymentMadeException(message);
    } catch (e) {
      throw PaymentMadeException(e.toString());
    }
  }

  Future<PaymentMade> createPaymentMade(PaymentMade pm) async {
    try {
      final body = pm.toJson();
      body.remove('id');
      final response = await _networkClient.post('/payments-made', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['payment'] != null) {
        return PaymentMade.fromJson(data['payment'] as Map<String, dynamic>);
      } else {
        throw PaymentMadeException('Invalid response structure for payment creation.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to record payment.';
      throw PaymentMadeException(message);
    } catch (e) {
      throw PaymentMadeException(e.toString());
    }
  }

  Future<void> deletePaymentMade(int id) async {
    try {
      await _networkClient.delete('/payments-made/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete payment.';
      throw PaymentMadeException(message);
    } catch (e) {
      throw PaymentMadeException(e.toString());
    }
  }
}

final paymentMadeServiceProvider = Provider<PaymentMadeService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return PaymentMadeService(networkClient);
});
