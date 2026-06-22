import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/vendors/data/models/vendor.dart';
import 'package:mobile_books/features/vendors/data/services/vendor_service.dart';

class VendorSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final vendorSearchQueryProvider = NotifierProvider<VendorSearchQueryNotifier, String>(() {
  return VendorSearchQueryNotifier();
});

class VendorsNotifier extends AsyncNotifier<List<Vendor>> {
  @override
  Future<List<Vendor>> build() {
    return ref.watch(vendorServiceProvider).getVendors();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(vendorServiceProvider).getVendors();
    });
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final service = ref.read(vendorServiceProvider);
    final result = await service.createVendor(vendor);
    ref.invalidateSelf();
    return result;
  }

  Future<Vendor> updateVendor(int id, Map<String, dynamic> updates) async {
    final service = ref.read(vendorServiceProvider);
    final result = await service.updateVendor(id, updates);
    ref.invalidateSelf();
    ref.invalidate(vendorDetailsProvider(id));
    return result;
  }

  Future<void> deleteVendor(int id) async {
    final service = ref.read(vendorServiceProvider);
    await service.deleteVendor(id);
    ref.invalidateSelf();
    ref.invalidate(vendorDetailsProvider(id));
  }
}

final vendorsProvider = AsyncNotifierProvider<VendorsNotifier, List<Vendor>>(() {
  return VendorsNotifier();
});

final filteredVendorsProvider = Provider<AsyncValue<List<Vendor>>>((ref) {
  final vendorsState = ref.watch(vendorsProvider);
  final searchQuery = ref.watch(vendorSearchQueryProvider).toLowerCase();

  return vendorsState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((v) {
      final name = v.displayName.toLowerCase();
      final company = (v.companyName ?? '').toLowerCase();
      final email = (v.email ?? '').toLowerCase();
      final phone = (v.phone ?? '').toLowerCase();
      return name.contains(searchQuery) ||
          company.contains(searchQuery) ||
          email.contains(searchQuery) ||
          phone.contains(searchQuery);
    }).toList();
  });
});

final vendorDetailsProvider = FutureProvider.family<Vendor, int>((ref, id) {
  return ref.watch(vendorServiceProvider).getVendorById(id);
});
