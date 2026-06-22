import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/data/models/customer_activity.dart';
import 'package:mobile_books/features/customers/data/models/customer_statement.dart';

class CustomerException implements Exception {
  final String message;
  CustomerException(this.message);

  @override
  String toString() => message;
}

class CustomerService {
  final NetworkClient _networkClient;

  CustomerService(this._networkClient);

  /// Fetches the list of all customers, with optional status filter ('active' or 'inactive').
  Future<List<Customer>> getCustomers({String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        'status': ?status,
      };

      final response = await _networkClient.get(
        '/customers',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final customersList = data['customers'] as List? ?? [];
      return customersList
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch customers list.';
      throw CustomerException(message);
    } catch (e) {
      throw CustomerException(e.toString());
    }
  }

  /// Fetches detailed records of a specific customer, including addresses and contact persons.
  Future<Customer> getCustomerById(int id) async {
    try {
      final response = await _networkClient.get('/customers/$id');
      final data = response.data as Map<String, dynamic>;

      if (data['customer'] != null) {
        final customerMap = Map<String, dynamic>.from(data['customer'] as Map);
        customerMap['addresses'] = data['addresses'];
        customerMap['contacts'] = data['contacts'];
        return Customer.fromJson(customerMap);
      } else {
        throw CustomerException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch customer details.';
      throw CustomerException(message);
    } catch (e) {
      throw CustomerException(e.toString());
    }
  }

  /// Creates a new customer record.
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final body = customer.toJson();
      // Remove ID from creation body
      body.remove('id');

      final response = await _networkClient.post(
        '/customers',
        data: body,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['customer'] != null) {
        return Customer.fromJson(data['customer'] as Map<String, dynamic>);
      } else {
        throw CustomerException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create customer.';
      throw CustomerException(message);
    } catch (e) {
      throw CustomerException(e.toString());
    }
  }

  /// Updates an existing customer profile.
  Future<Customer> updateCustomer(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put(
        '/customers/$id',
        data: updates,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['customer'] != null) {
        return Customer.fromJson(data['customer'] as Map<String, dynamic>);
      } else {
        throw CustomerException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update customer.';
      throw CustomerException(message);
    } catch (e) {
      throw CustomerException(e.toString());
    }
  }

  /// Performs hard delete of a customer on the backend.
  Future<void> deleteCustomer(int id) async {
    try {
      await _networkClient.delete('/customers/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete customer.';
      throw CustomerException(message);
    } catch (e) {
      throw CustomerException(e.toString());
    }
  }

  /// Fetches the recent activity logs for a customer.
  Future<List<CustomerActivity>> getActivityLog(int id) async {
    try {
      final response = await _networkClient.get('/customers/$id/activity');
      final data = response.data as Map<String, dynamic>;
      final activitiesList = data['activities'] as List? ?? [];
      return activitiesList
          .map((e) => CustomerActivity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch customer activity logs.';
      throw CustomerException(message);
    } catch (e) {
      throw CustomerException(e.toString());
    }
  }

  /// Fetches the customer ledger statement of accounts.
  Future<CustomerStatement> getCustomerStatement(
    int id, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'start_date': ?startDate,
        'end_date': ?endDate,
      };

      final response = await _networkClient.get(
        '/customers/$id/statement',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      return CustomerStatement.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch statement statement.';
      throw CustomerException(message);
    } catch (e) {
      throw CustomerException(e.toString());
    }
  }
}

final customerServiceProvider = Provider<CustomerService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return CustomerService(networkClient);
});
