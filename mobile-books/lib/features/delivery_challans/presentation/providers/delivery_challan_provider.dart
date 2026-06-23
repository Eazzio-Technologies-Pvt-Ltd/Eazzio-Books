import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan_item.dart';
import 'package:mobile_books/features/delivery_challans/data/services/delivery_challan_service.dart';

class DeliveryChallansNotifier extends AsyncNotifier<List<DeliveryChallan>> {
  @override
  Future<List<DeliveryChallan>> build() {
    return ref.watch(deliveryChallanServiceProvider).getDeliveryChallans();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(deliveryChallanServiceProvider).getDeliveryChallans();
    });
  }

  Future<DeliveryChallan> createDeliveryChallan(DeliveryChallan dc, List<DeliveryChallanItem> items) async {
    final service = ref.read(deliveryChallanServiceProvider);
    final result = await service.createDeliveryChallan(dc, items);
    ref.invalidateSelf();
    return result;
  }

  Future<void> updateDeliveryChallan(int id, Map<String, dynamic> updates) async {
    final service = ref.read(deliveryChallanServiceProvider);
    await service.updateDeliveryChallan(id, updates);
    ref.invalidateSelf();
    ref.invalidate(deliveryChallanDetailsProvider(id));
  }

  Future<void> deleteDeliveryChallan(int id) async {
    final service = ref.read(deliveryChallanServiceProvider);
    await service.deleteDeliveryChallan(id);
    ref.invalidateSelf();
    ref.invalidate(deliveryChallanDetailsProvider(id));
  }

  Future<void> cancelDeliveryChallan(int id) async {
    final service = ref.read(deliveryChallanServiceProvider);
    await service.cancelDeliveryChallan(id);
    ref.invalidateSelf();
    ref.invalidate(deliveryChallanDetailsProvider(id));
  }

  Future<void> markDelivered(int id) async {
    final service = ref.read(deliveryChallanServiceProvider);
    await service.markDelivered(id);
    ref.invalidateSelf();
    ref.invalidate(deliveryChallanDetailsProvider(id));
  }

  Future<int> convertFromSalesOrder(int salesOrderId) async {
    final service = ref.read(deliveryChallanServiceProvider);
    final dcId = await service.convertFromSalesOrder(salesOrderId);
    ref.invalidateSelf();
    return dcId;
  }

  Future<int> convertDeliveryChallanToInvoice(int id) async {
    final service = ref.read(deliveryChallanServiceProvider);
    final invoiceId = await service.convertDeliveryChallanToInvoice(id);
    ref.invalidateSelf();
    return invoiceId;
  }

  Future<void> sendEmail(int id, {
    required String to,
    required String subject,
    required String body,
  }) async {
    final service = ref.read(deliveryChallanServiceProvider);
    await service.sendEmail(id, to: to, subject: subject, body: body);
    ref.invalidateSelf();
    ref.invalidate(deliveryChallanDetailsProvider(id));
  }

  /// Marks a delivery challan as sent explicitly
  Future<void> markAsSent(int id) async {
    final service = ref.read(deliveryChallanServiceProvider);
    await service.markDeliveryChallanAsSent(id);
    ref.invalidateSelf();
    ref.invalidate(deliveryChallanDetailsProvider(id));
  }
}

final deliveryChallansProvider =
    AsyncNotifierProvider<DeliveryChallansNotifier, List<DeliveryChallan>>(() {
  return DeliveryChallansNotifier();
});

final deliveryChallanDetailsProvider =
    FutureProvider.family<DeliveryChallanDetails, int>((ref, id) {
  return ref.watch(deliveryChallanServiceProvider).getDeliveryChallanById(id);
});
