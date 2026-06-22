import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/quotes/data/models/salesperson.dart';

class SalespersonService {
  final NetworkClient _networkClient;

  SalespersonService(this._networkClient);

  /// Fetches all salespersons
  Future<List<Salesperson>> getSalespersons() async {
    try {
      final response = await _networkClient.get('/salespersons');
      final data = response.data as Map<String, dynamic>;
      final list = data['salespersons'] as List? ?? [];
      return list.map((e) => Salesperson.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch salespersons list.';
      throw Exception(message);
    }
  }

  /// Creates a new salesperson
  Future<Salesperson> createSalesperson({
    required String name,
    String? email,
    String? phone,
    String? employeeId,
  }) async {
    try {
      final body = {
        'name': name.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (employeeId != null && employeeId.trim().isNotEmpty) 'employee_id': employeeId.trim(),
      };
      final response = await _networkClient.post('/salespersons', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['salesperson'] != null) {
        return Salesperson.fromJson(data['salesperson'] as Map<String, dynamic>);
      }
      throw Exception('Salesperson details not found in response');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create salesperson.';
      throw Exception(message);
    }
  }
}

final salespersonServiceProvider = Provider<SalespersonService>((ref) {
  return SalespersonService(ref.watch(networkClientProvider));
});
