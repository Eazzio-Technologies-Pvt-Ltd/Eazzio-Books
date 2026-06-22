import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit_item.dart';
import 'package:mobile_books/features/vendor_credits/data/services/vendor_credit_service.dart';

class VendorCreditSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final vendorCreditSearchQueryProvider = NotifierProvider<VendorCreditSearchQueryNotifier, String>(() {
  return VendorCreditSearchQueryNotifier();
});

class VendorCreditsNotifier extends AsyncNotifier<List<VendorCredit>> {
  @override
  Future<List<VendorCredit>> build() {
    return ref.watch(vendorCreditServiceProvider).getVendorCredits();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(vendorCreditServiceProvider).getVendorCredits();
    });
  }

  Future<VendorCredit> createVendorCredit(VendorCredit vc, List<VendorCreditItem> items) async {
    final service = ref.read(vendorCreditServiceProvider);
    final result = await service.createVendorCredit(vc, items);
    ref.invalidateSelf();
    return result;
  }

  Future<void> updateVendorCredit(int id, Map<String, dynamic> updates) async {
    final service = ref.read(vendorCreditServiceProvider);
    await service.updateVendorCredit(id, updates);
    ref.invalidateSelf();
    ref.invalidate(vendorCreditDetailsProvider(id));
  }

  Future<void> deleteVendorCredit(int id) async {
    final service = ref.read(vendorCreditServiceProvider);
    await service.deleteVendorCredit(id);
    ref.invalidateSelf();
    ref.invalidate(vendorCreditDetailsProvider(id));
  }

  Future<void> applyCredit(int id, int billId, double amount) async {
    final service = ref.read(vendorCreditServiceProvider);
    await service.applyCredit(id, billId, amount);
    ref.invalidateSelf();
    ref.invalidate(vendorCreditDetailsProvider(id));
  }
}

final vendorCreditsProvider = AsyncNotifierProvider<VendorCreditsNotifier, List<VendorCredit>>(() {
  return VendorCreditsNotifier();
});

final filteredVendorCreditsProvider = Provider<AsyncValue<List<VendorCredit>>>((ref) {
  final vcState = ref.watch(vendorCreditsProvider);
  final searchQuery = ref.watch(vendorCreditSearchQueryProvider).toLowerCase();

  return vcState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((vc) {
      final num = vc.vendorCreditNumber.toLowerCase();
      final status = vc.status.toLowerCase();
      final reason = (vc.reason ?? '').toLowerCase();
      return num.contains(searchQuery) || status.contains(searchQuery) || reason.contains(searchQuery);
    }).toList();
  });
});

final vendorCreditDetailsProvider = FutureProvider.family<VendorCreditDetails, int>((ref, id) {
  return ref.watch(vendorCreditServiceProvider).getVendorCreditById(id);
});
