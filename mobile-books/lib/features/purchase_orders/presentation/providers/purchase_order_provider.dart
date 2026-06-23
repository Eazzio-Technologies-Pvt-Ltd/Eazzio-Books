import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/purchase_orders/data/models/purchase_order.dart';
import 'package:mobile_books/features/purchase_orders/data/models/purchase_order_item.dart';
import 'package:mobile_books/features/purchase_orders/data/services/purchase_order_service.dart';

class PurchaseOrderSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final purchaseOrderSearchQueryProvider = NotifierProvider<PurchaseOrderSearchQueryNotifier, String>(() {
  return PurchaseOrderSearchQueryNotifier();
});

class PurchaseOrdersNotifier extends AsyncNotifier<List<PurchaseOrder>> {
  @override
  Future<List<PurchaseOrder>> build() {
    return ref.watch(purchaseOrderServiceProvider).getPurchaseOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(purchaseOrderServiceProvider).getPurchaseOrders();
    });
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po, List<PurchaseOrderItem> items) async {
    final service = ref.read(purchaseOrderServiceProvider);
    final result = await service.createPurchaseOrder(po, items);
    ref.invalidateSelf();
    return result;
  }

  Future<void> updatePurchaseOrder(int id, Map<String, dynamic> updates) async {
    final service = ref.read(purchaseOrderServiceProvider);
    await service.updatePurchaseOrder(id, updates);
    ref.invalidateSelf();
    ref.invalidate(purchaseOrderDetailsProvider(id));
  }

  Future<void> deletePurchaseOrder(int id) async {
    final service = ref.read(purchaseOrderServiceProvider);
    await service.deletePurchaseOrder(id);
    ref.invalidateSelf();
    ref.invalidate(purchaseOrderDetailsProvider(id));
  }

  Future<int> convertToBill(int id) async {
    final service = ref.read(purchaseOrderServiceProvider);
    final billId = await service.convertToBill(id);
    ref.invalidateSelf();
    return billId;
  }

  Future<void> sendEmail(int id, {
    required String to,
    required String subject,
    required String body,
  }) async {
    final service = ref.read(purchaseOrderServiceProvider);
    await service.sendEmail(id, {'to': to, 'subject': subject, 'body': body});
    ref.invalidateSelf();
    ref.invalidate(purchaseOrderDetailsProvider(id));
  }
}

final purchaseOrdersProvider = AsyncNotifierProvider<PurchaseOrdersNotifier, List<PurchaseOrder>>(() {
  return PurchaseOrdersNotifier();
});

final filteredPurchaseOrdersProvider = Provider<AsyncValue<List<PurchaseOrder>>>((ref) {
  final poState = ref.watch(purchaseOrdersProvider);
  final searchQuery = ref.watch(purchaseOrderSearchQueryProvider).toLowerCase();

  return poState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((po) {
      final num = po.purchaseOrderNumber.toLowerCase();
      final status = po.status.toLowerCase();
      final refNum = (po.referenceNumber ?? '').toLowerCase();
      return num.contains(searchQuery) || status.contains(searchQuery) || refNum.contains(searchQuery);
    }).toList();
  });
});

final purchaseOrderDetailsProvider = FutureProvider.family<PurchaseOrderDetails, int>((ref, id) {
  return ref.watch(purchaseOrderServiceProvider).getPurchaseOrderById(id);
});
