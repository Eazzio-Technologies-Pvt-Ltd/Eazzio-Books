import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/payments_made/data/models/payment_made.dart';
import 'package:mobile_books/features/payments_made/data/services/payment_made_service.dart';

class PaymentMadeSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final paymentMadeSearchQueryProvider = NotifierProvider<PaymentMadeSearchQueryNotifier, String>(() {
  return PaymentMadeSearchQueryNotifier();
});

class PaymentsMadeNotifier extends AsyncNotifier<List<PaymentMade>> {
  @override
  Future<List<PaymentMade>> build() {
    return ref.watch(paymentMadeServiceProvider).getPaymentsMade();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(paymentMadeServiceProvider).getPaymentsMade();
    });
  }

  Future<PaymentMade> createPaymentMade(PaymentMade pm) async {
    final service = ref.read(paymentMadeServiceProvider);
    final result = await service.createPaymentMade(pm);
    ref.invalidateSelf();
    return result;
  }

  Future<void> deletePaymentMade(int id) async {
    final service = ref.read(paymentMadeServiceProvider);
    await service.deletePaymentMade(id);
    ref.invalidateSelf();
    ref.invalidate(paymentMadeDetailsProvider(id));
  }
}

final paymentsMadeProvider = AsyncNotifierProvider<PaymentsMadeNotifier, List<PaymentMade>>(() {
  return PaymentsMadeNotifier();
});

final filteredPaymentsMadeProvider = Provider<AsyncValue<List<PaymentMade>>>((ref) {
  final pmState = ref.watch(paymentsMadeProvider);
  final searchQuery = ref.watch(paymentMadeSearchQueryProvider).toLowerCase();

  return pmState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((pm) {
      final vendor = (pm.vendorName ?? '').toLowerCase();
      final mode = (pm.paymentMode ?? '').toLowerCase();
      final refNum = (pm.referenceNumber ?? '').toLowerCase();
      final billNum = (pm.billNumber ?? '').toLowerCase();
      return vendor.contains(searchQuery) ||
          mode.contains(searchQuery) ||
          refNum.contains(searchQuery) ||
          billNum.contains(searchQuery);
    }).toList();
  });
});

final paymentMadeDetailsProvider = FutureProvider.family<PaymentMade, int>((ref, id) {
  return ref.watch(paymentMadeServiceProvider).getPaymentMadeById(id);
});
