import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/vendors/data/models/vendor.dart';

class VendorException implements Exception {
  final String message;
  VendorException(this.message);

  @override
  String toString() => message;
}

class VendorService {
  final NetworkClient _networkClient;

  VendorService(this._networkClient);

  Future<List<Vendor>> getVendors() async {
    try {
      final response = await _networkClient.get('/vendors');
      final data = response.data as Map<String, dynamic>;
      final list = data['vendors'] as List? ?? [];
      return list.map((e) => Vendor.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch vendors.';
      throw VendorException(message);
    } catch (e) {
      throw VendorException(e.toString());
    }
  }

  Future<Vendor> getVendorById(int id) async {
    try {
      final response = await _networkClient.get('/vendors/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['vendor'] != null) {
        return Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
      } else {
        throw VendorException('Invalid vendor response structure.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch vendor details.';
      throw VendorException(message);
    } catch (e) {
      throw VendorException(e.toString());
    }
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    try {
      final body = vendor.toJson();
      body.remove('id'); // ID is serial
      final response = await _networkClient.post('/vendors', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['vendor'] != null) {
        return Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
      } else {
        throw VendorException('Failed to parse created vendor.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create vendor.';
      throw VendorException(message);
    } catch (e) {
      throw VendorException(e.toString());
    }
  }

  Future<Vendor> updateVendor(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/vendors/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['vendor'] != null) {
        return Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
      } else {
        throw VendorException('Failed to parse updated vendor.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update vendor.';
      throw VendorException(message);
    } catch (e) {
      throw VendorException(e.toString());
    }
  }

  Future<void> deleteVendor(int id) async {
    try {
      await _networkClient.delete('/vendors/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete vendor.';
      throw VendorException(message);
    } catch (e) {
      throw VendorException(e.toString());
    }
  }
}

final vendorServiceProvider = Provider<VendorService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return VendorService(networkClient);
});
