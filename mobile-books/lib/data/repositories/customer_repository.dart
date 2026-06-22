import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/customer_model.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return CustomerRepository(apiClient);
});

class CustomerRepository {
  final ApiClient _apiClient;

  CustomerRepository(this._apiClient);

  Future<List<CustomerModel>> getCustomers() async {
    final response = await _apiClient.get('/api/customers');
    final List<dynamic> customersData = response.data['customers'] ?? [];
    return customersData.map((json) => CustomerModel.fromJson(json)).toList();
  }

  Future<CustomerModel> getCustomerById(int id) async {
    final response = await _apiClient.get('/api/customers/$id');
    final customerData = response.data['customer'];
    return CustomerModel.fromJson(customerData);
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> customerData) async {
    final response = await _apiClient.post('/api/customers', data: customerData);
    return CustomerModel.fromJson(response.data['customer']);
  }

  Future<CustomerModel> updateCustomer(int id, Map<String, dynamic> customerData) async {
    final response = await _apiClient.put('/api/customers/$id', data: customerData);
    return CustomerModel.fromJson(response.data['customer']);
  }

  Future<void> deleteCustomer(int id) async {
    await _apiClient.delete('/api/customers/$id');
  }
}
