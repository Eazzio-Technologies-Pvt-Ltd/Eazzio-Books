import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/bulk_updates/data/models/bulk_update_log.dart';
import 'package:mobile_books/features/bulk_updates/data/services/bulk_update_service.dart';

class BulkUpdateLogsNotifier extends AsyncNotifier<List<BulkUpdateLog>> {
  @override
  Future<List<BulkUpdateLog>> build() {
    return ref.watch(bulkUpdateServiceProvider).getLogs();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final bulkUpdateLogsProvider = AsyncNotifierProvider<BulkUpdateLogsNotifier, List<BulkUpdateLog>>(() {
  return BulkUpdateLogsNotifier();
});

final bulkUpdateModulesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(bulkUpdateServiceProvider).getModules();
});

class SelectedBulkUpdateModuleNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final selectedBulkUpdateModuleProvider = NotifierProvider<SelectedBulkUpdateModuleNotifier, String>(() {
  return SelectedBulkUpdateModuleNotifier();
});

final bulkUpdateModuleRecordsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final module = ref.watch(selectedBulkUpdateModuleProvider);
  if (module.isEmpty) return [];
  return ref.watch(bulkUpdateServiceProvider).getRecordsForModule(module);
});
