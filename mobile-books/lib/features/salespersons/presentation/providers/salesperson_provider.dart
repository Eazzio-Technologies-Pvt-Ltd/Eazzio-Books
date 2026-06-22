import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/quotes/data/models/salesperson.dart';
import 'package:mobile_books/features/salespersons/data/services/salesperson_service.dart';

class SalespersonsListNotifier extends AsyncNotifier<List<Salesperson>> {
  @override
  Future<List<Salesperson>> build() {
    return ref.watch(salespersonServiceProvider).getSalespersons();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(salespersonServiceProvider).getSalespersons();
    });
  }

  Future<Salesperson> createSalesperson({
    required String name,
    String? email,
    String? phone,
    String? employeeId,
  }) async {
    final service = ref.read(salespersonServiceProvider);
    final result = await service.createSalesperson(
      name: name,
      email: email,
      phone: phone,
      employeeId: employeeId,
    );
    ref.invalidateSelf();
    return result;
  }
}

final salespersonsListProvider =
    AsyncNotifierProvider<SalespersonsListNotifier, List<Salesperson>>(() {
  return SalespersonsListNotifier();
});
