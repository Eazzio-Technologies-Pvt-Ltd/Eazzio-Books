import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/data/models/customer_activity.dart';
import 'package:mobile_books/features/customers/data/models/customer_statement.dart';
import 'package:mobile_books/features/customers/data/services/customer_service.dart';

class CustomersListFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

/// Filter state for customer list: 'active', 'inactive', or null (all)
final customersListFilterProvider = NotifierProvider<CustomersListFilterNotifier, String?>(() {
  return CustomersListFilterNotifier();
});

class CustomerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

/// Search query state for customer list
final customerSearchQueryProvider = NotifierProvider<CustomerSearchQueryNotifier, String>(() {
  return CustomerSearchQueryNotifier();
});

/// Notifier that manages the active list of customers
class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() {
    final status = ref.watch(customersListFilterProvider);
    return ref.watch(customerServiceProvider).getCustomers(status: status);
  }

  /// Explicitly reloads customer listings from backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final status = ref.watch(customersListFilterProvider);
      return ref.read(customerServiceProvider).getCustomers(status: status);
    });
  }

  /// Dispatches customer creation and refreshes listings.
  Future<Customer> createCustomer(Customer customer) async {
    final service = ref.read(customerServiceProvider);
    final result = await service.createCustomer(customer);
    ref.invalidateSelf(); // Force rebuild to update list views
    return result;
  }

  /// Dispatches customer updates and invalidates cache.
  Future<Customer> updateCustomer(int id, Map<String, dynamic> updates) async {
    final service = ref.read(customerServiceProvider);
    final result = await service.updateCustomer(id, updates);
    ref.invalidateSelf();
    ref.invalidate(customerDetailsProvider(id)); // Invalidate detail cache
    return result;
  }

  /// Dispatches customer deletion and updates list views.
  Future<void> deleteCustomer(int id) async {
    final service = ref.read(customerServiceProvider);
    await service.deleteCustomer(id);
    ref.invalidateSelf();
    ref.invalidate(customerDetailsProvider(id));
  }
}

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
  return CustomersNotifier();
});

/// Filtered list of customers matching search query
final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customersState = ref.watch(customersProvider);
  final searchQuery = ref.watch(customerSearchQueryProvider).toLowerCase();

  return customersState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((customer) {
      final name = customer.formattedName.toLowerCase();
      final email = (customer.email ?? '').toLowerCase();
      final company = (customer.companyName ?? '').toLowerCase();
      final phone = (customer.phone ?? '').toLowerCase();
      final mobile = (customer.mobile ?? '').toLowerCase();
      return name.contains(searchQuery) ||
          email.contains(searchQuery) ||
          company.contains(searchQuery) ||
          phone.contains(searchQuery) ||
          mobile.contains(searchQuery);
    }).toList();
  });
});

/// Fetches customer detailed details by ID (addresses and contacts merged)
final customerDetailsProvider = FutureProvider.family<Customer, int>((ref, id) {
  return ref.watch(customerServiceProvider).getCustomerById(id);
});

/// Fetches recent activities for a customer
final customerActivityProvider = FutureProvider.family<List<CustomerActivity>, int>((ref, id) {
  return ref.watch(customerServiceProvider).getActivityLog(id);
});

class StatementDateRangeNotifier extends Notifier<DateTimeRange?> {
  final int customerId;
  StatementDateRangeNotifier(this.customerId);

  @override
  DateTimeRange? build() => null;

  @override
  set state(DateTimeRange? value) => super.state = value;
}

/// State for customer statement date filters
final statementDateRangeProvider = NotifierProvider.family<StatementDateRangeNotifier, DateTimeRange?, int>((id) {
  return StatementDateRangeNotifier(id);
});

/// Fetches ledger statement of accounts for a customer
final customerStatementProvider = FutureProvider.family<CustomerStatement, int>((ref, id) {
  final dateRange = ref.watch(statementDateRangeProvider(id));
  
  String? startDateStr;
  String? endDateStr;

  if (dateRange != null) {
    startDateStr = dateRange.start.toIso8601String().split('T')[0];
    endDateStr = dateRange.end.toIso8601String().split('T')[0];
  }

  return ref.watch(customerServiceProvider).getCustomerStatement(
    id,
    startDate: startDateStr,
    endDate: endDateStr,
  );
});
