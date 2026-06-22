import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/settings/data/models/organization_settings.dart';
import 'package:mobile_books/features/settings/data/models/tax.dart';
import 'package:mobile_books/features/settings/data/services/settings_service.dart';

class OrganizationSettingsNotifier extends AsyncNotifier<OrganizationSettings> {
  @override
  Future<OrganizationSettings> build() {
    return ref.watch(settingsServiceProvider).getOrganizationSettings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(settingsServiceProvider).getOrganizationSettings();
    });
  }

  Future<void> updateSettings(OrganizationSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(settingsServiceProvider).updateOrganizationSettings(settings);
    });
  }
}

final organizationSettingsProvider =
    AsyncNotifierProvider<OrganizationSettingsNotifier, OrganizationSettings>(() {
  return OrganizationSettingsNotifier();
});

class TaxesNotifier extends AsyncNotifier<List<Tax>> {
  @override
  Future<List<Tax>> build() {
    return ref.watch(settingsServiceProvider).getTaxes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(settingsServiceProvider).getTaxes();
    });
  }

  Future<Tax> createTax(Tax tax) async {
    final service = ref.read(settingsServiceProvider);
    final result = await service.createTax(tax);
    ref.invalidateSelf();
    return result;
  }

  Future<Tax> updateTax(int id, Map<String, dynamic> updates) async {
    final service = ref.read(settingsServiceProvider);
    final result = await service.updateTax(id, updates);
    ref.invalidateSelf();
    return result;
  }

  Future<void> deleteTax(int id) async {
    final service = ref.read(settingsServiceProvider);
    await service.deleteTax(id);
    ref.invalidateSelf();
  }
}

final taxesProvider = AsyncNotifierProvider<TaxesNotifier, List<Tax>>(() {
  return TaxesNotifier();
});
