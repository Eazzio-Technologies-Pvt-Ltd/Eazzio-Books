import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/bills/data/models/bill.dart';
import 'package:mobile_books/features/bills/data/models/bill_item.dart';
import 'package:mobile_books/features/bills/data/services/bill_service.dart';

class BillSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final billSearchQueryProvider = NotifierProvider<BillSearchQueryNotifier, String>(() {
  return BillSearchQueryNotifier();
});

class BillsNotifier extends AsyncNotifier<List<Bill>> {
  @override
  Future<List<Bill>> build() {
    return ref.watch(billServiceProvider).getBills();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(billServiceProvider).getBills();
    });
  }

  Future<Bill> createBill(Bill bill, List<BillItem> items) async {
    final service = ref.read(billServiceProvider);
    final result = await service.createBill(bill, items);
    ref.invalidateSelf();
    return result;
  }

  Future<void> updateBill(int id, Map<String, dynamic> updates) async {
    final service = ref.read(billServiceProvider);
    await service.updateBill(id, updates);
    ref.invalidateSelf();
    ref.invalidate(billDetailsProvider(id));
  }

  Future<void> deleteBill(int id) async {
    final service = ref.read(billServiceProvider);
    await service.deleteBill(id);
    ref.invalidateSelf();
    ref.invalidate(billDetailsProvider(id));
  }
}

final billsProvider = AsyncNotifierProvider<BillsNotifier, List<Bill>>(() {
  return BillsNotifier();
});

final filteredBillsProvider = Provider<AsyncValue<List<Bill>>>((ref) {
  final billsState = ref.watch(billsProvider);
  final searchQuery = ref.watch(billSearchQueryProvider).toLowerCase();

  return billsState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((b) {
      final num = b.billNumber.toLowerCase();
      final status = b.status.toLowerCase();
      final notes = (b.notes ?? '').toLowerCase();
      return num.contains(searchQuery) || status.contains(searchQuery) || notes.contains(searchQuery);
    }).toList();
  });
});

final billDetailsProvider = FutureProvider.family<BillDetails, int>((ref, id) {
  return ref.watch(billServiceProvider).getBillById(id);
});
