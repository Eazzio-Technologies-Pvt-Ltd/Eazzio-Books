import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer_model.dart';
import '../data/repositories/customer_repository.dart';

class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? errorMessage;
  final bool isOperationSuccess;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isOperationSuccess = false,
  });

  CustomerState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? errorMessage,
    bool? isOperationSuccess,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isOperationSuccess: isOperationSuccess ?? this.isOperationSuccess,
    );
  }
}

class CustomerNotifier extends Notifier<CustomerState> {
  @override
  CustomerState build() {
    Future.microtask(() => fetchCustomers());
    return const CustomerState();
  }

  Future<void> fetchCustomers() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(customerRepositoryProvider);
      final customers = await repository.getCustomers();
      state = state.copyWith(isLoading: false, customers: customers);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addCustomer(Map<String, dynamic> customerData) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(customerRepositoryProvider);
      final newCustomer = await repository.createCustomer(customerData);
      state = state.copyWith(
        isLoading: false,
        customers: [newCustomer, ...state.customers],
        isOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> editCustomer(int id, Map<String, dynamic> customerData) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(customerRepositoryProvider);
      final updatedCustomer = await repository.updateCustomer(id, customerData);
      state = state.copyWith(
        isLoading: false,
        customers: state.customers.map((c) => c.id == id ? updatedCustomer : c).toList(),
        isOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> removeCustomer(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(customerRepositoryProvider);
      await repository.deleteCustomer(id);
      state = state.copyWith(
        isLoading: false,
        customers: state.customers.where((c) => c.id != id).toList(),
        isOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final customerProvider = NotifierProvider<CustomerNotifier, CustomerState>(() {
  return CustomerNotifier();
});
