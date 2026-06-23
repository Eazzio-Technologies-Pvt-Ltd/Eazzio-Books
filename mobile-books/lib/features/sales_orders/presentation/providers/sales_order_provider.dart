import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order_item.dart';
import 'package:mobile_books/features/sales_orders/data/services/sales_order_service.dart';

class SalesOrdersListFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final salesOrdersListFilterProvider =
    NotifierProvider<SalesOrdersListFilterNotifier, String>(() {
  return SalesOrdersListFilterNotifier();
});

class SalesOrderSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final salesOrderSearchQueryProvider =
    NotifierProvider<SalesOrderSearchQueryNotifier, String>(() {
  return SalesOrderSearchQueryNotifier();
});

class SalesOrdersNotifier extends AsyncNotifier<List<SalesOrder>> {
  @override
  Future<List<SalesOrder>> build() {
    ref.watch(authNotifierProvider);
    return ref.watch(salesOrderServiceProvider).getSalesOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(salesOrderServiceProvider).getSalesOrders();
    });
  }

  Future<SalesOrder> createSalesOrder(SalesOrder order, List<SalesOrderItem> items) async {
    final service = ref.read(salesOrderServiceProvider);
    final result = await service.createSalesOrder(order, items);
    ref.invalidateSelf();
    return result;
  }

  Future<SalesOrder> updateSalesOrder(int id, Map<String, dynamic> updates) async {
    final service = ref.read(salesOrderServiceProvider);
    final result = await service.updateSalesOrder(id, updates);
    ref.invalidateSelf();
    ref.invalidate(salesOrderDetailsProvider(id));
    return result;
  }

  Future<void> deleteSalesOrder(int id) async {
    final service = ref.read(salesOrderServiceProvider);
    await service.deleteSalesOrder(id);
    ref.invalidateSelf();
    ref.invalidate(salesOrderDetailsProvider(id));
  }

  Future<Map<String, dynamic>> convertToInvoice(int id) async {
    final service = ref.read(salesOrderServiceProvider);
    final result = await service.convertSalesOrderToInvoice(id);
    ref.invalidateSelf();
    ref.invalidate(salesOrderDetailsProvider(id));
    return result;
  }

  Future<void> sendEmail(int id, Map<String, dynamic> emailPayload) async {
    final service = ref.read(salesOrderServiceProvider);
    await service.sendSalesOrderEmail(id, emailPayload);
    ref.invalidateSelf();
    ref.invalidate(salesOrderDetailsProvider(id));
  }

  /// Marks a sales order as sent/confirmed explicitly
  Future<void> markAsSent(int id) async {
    final service = ref.read(salesOrderServiceProvider);
    await service.markSalesOrderAsSent(id);
    ref.invalidateSelf();
    ref.invalidate(salesOrderDetailsProvider(id));
  }
}

final salesOrdersProvider =
    AsyncNotifierProvider<SalesOrdersNotifier, List<SalesOrder>>(() {
  return SalesOrdersNotifier();
});

final filteredSalesOrdersProvider = Provider<AsyncValue<List<SalesOrder>>>((ref) {
  final salesOrdersState = ref.watch(salesOrdersProvider);
  final filter = ref.watch(salesOrdersListFilterProvider);
  final searchQuery = ref.watch(salesOrderSearchQueryProvider).toLowerCase();

  return salesOrdersState.whenData((list) {
    var result = list;

    if (filter != 'all') {
      result = result.where((o) => o.status.toLowerCase() == filter).toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((o) {
        final number = o.salesOrderNumber.toLowerCase();
        final notes = (o.notes ?? '').toLowerCase();
        final terms = (o.terms ?? '').toLowerCase();
        final status = o.status.toLowerCase();
        final refNum = (o.referenceNumber ?? '').toLowerCase();
        return number.contains(searchQuery) ||
            notes.contains(searchQuery) ||
            terms.contains(searchQuery) ||
            status.contains(searchQuery) ||
            refNum.contains(searchQuery);
      }).toList();
    }

    return result;
  });
});

final salesOrderDetailsProvider =
    FutureProvider.family<SalesOrderDetails, int>((ref, id) {
  ref.watch(authNotifierProvider);
  return ref.watch(salesOrderServiceProvider).getSalesOrderById(id);
});
