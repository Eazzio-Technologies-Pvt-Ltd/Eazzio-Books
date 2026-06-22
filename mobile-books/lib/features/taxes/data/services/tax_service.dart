import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/taxes/data/models/tax_rate.dart';

class TaxException implements Exception {
  final String message;
  TaxException(this.message);

  @override
  String toString() => message;
}

class TaxService {
  final NetworkClient _networkClient;

  TaxService(this._networkClient);

  Future<List<TaxRate>> getTaxes() async {
    try {
      final response = await _networkClient.get('/taxes');
      final data = response.data as Map<String, dynamic>;
      final list = data['taxes'] as List? ?? [];
      return list.map((e) => TaxRate.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch taxes.';
      throw TaxException(message);
    } catch (e) {
      throw TaxException(e.toString());
    }
  }

  Future<TaxRate> getTaxById(int id) async {
    try {
      final response = await _networkClient.get('/taxes/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['tax'] != null) {
        return TaxRate.fromJson(data['tax'] as Map<String, dynamic>);
      } else {
        throw TaxException('Invalid tax rate details.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch tax details.';
      throw TaxException(message);
    } catch (e) {
      throw TaxException(e.toString());
    }
  }

  Future<TaxRate> createTax(TaxRate tax) async {
    try {
      final body = tax.toJson();
      body.remove('id');
      body.remove('user_id');
      body.remove('created_at');
      body.remove('updated_at');
      final response = await _networkClient.post('/taxes', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['tax'] != null) {
        return TaxRate.fromJson(data['tax'] as Map<String, dynamic>);
      } else {
        throw TaxException('Failed to parse created tax.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create tax.';
      throw TaxException(message);
    } catch (e) {
      throw TaxException(e.toString());
    }
  }

  Future<TaxRate> updateTax(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/taxes/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['tax'] != null) {
        return TaxRate.fromJson(data['tax'] as Map<String, dynamic>);
      } else {
        throw TaxException('Failed to parse updated tax.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update tax.';
      throw TaxException(message);
    } catch (e) {
      throw TaxException(e.toString());
    }
  }

  Future<void> deleteTax(int id) async {
    try {
      await _networkClient.delete('/taxes/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete tax.';
      throw TaxException(message);
    } catch (e) {
      throw TaxException(e.toString());
    }
  }
}

final taxServiceProvider = Provider<TaxService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return TaxService(networkClient);
});
