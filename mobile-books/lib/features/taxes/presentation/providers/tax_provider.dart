import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/taxes/data/models/tax_rate.dart';
import 'package:mobile_books/features/taxes/data/services/tax_service.dart';

class TaxesNotifier extends AsyncNotifier<List<TaxRate>> {
  @override
  Future<List<TaxRate>> build() {
    return ref.watch(taxServiceProvider).getTaxes();
  }

  Future<TaxRate> createTax(TaxRate tax) async {
    final service = ref.read(taxServiceProvider);
    final result = await service.createTax(tax);
    ref.invalidateSelf();
    return result;
  }

  Future<TaxRate> updateTax(int id, Map<String, dynamic> updates) async {
    final service = ref.read(taxServiceProvider);
    final result = await service.updateTax(id, updates);
    ref.invalidateSelf();
    ref.invalidate(taxDetailsProvider(id));
    return result;
  }

  Future<void> deleteTax(int id) async {
    final service = ref.read(taxServiceProvider);
    await service.deleteTax(id);
    ref.invalidateSelf();
    ref.invalidate(taxDetailsProvider(id));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final taxesProvider = AsyncNotifierProvider<TaxesNotifier, List<TaxRate>>(() {
  return TaxesNotifier();
});

final taxDetailsProvider = FutureProvider.family<TaxRate, int>((ref, id) {
  return ref.watch(taxServiceProvider).getTaxById(id);
});

class TaxSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final taxSearchQueryProvider = NotifierProvider<TaxSearchQueryNotifier, String>(() {
  return TaxSearchQueryNotifier();
});

class TaxTypeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final taxTypeFilterProvider = NotifierProvider<TaxTypeFilterNotifier, String>(() {
  return TaxTypeFilterNotifier();
});

class TaxStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final taxStatusFilterProvider = NotifierProvider<TaxStatusFilterNotifier, String>(() {
  return TaxStatusFilterNotifier();
});

final filteredTaxesProvider = Provider<List<TaxRate>>((ref) {
  final taxesState = ref.watch(taxesProvider);
  final query = ref.watch(taxSearchQueryProvider).toLowerCase();
  final typeFilter = ref.watch(taxTypeFilterProvider);
  final statusFilter = ref.watch(taxStatusFilterProvider);

  return taxesState.maybeWhen(
    data: (list) {
      return list.where((t) {
        final matchesQuery = t.taxName.toLowerCase().contains(query);
        final matchesType = typeFilter == 'all' || t.taxType == typeFilter;
        final matchesStatus = statusFilter == 'all' || t.status == statusFilter;
        return matchesQuery && matchesType && matchesStatus;
      }).toList();
    },
    orElse: () => [],
  );
});
