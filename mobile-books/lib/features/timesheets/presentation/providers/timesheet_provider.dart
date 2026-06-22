import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/timesheets/data/models/timesheet.dart';
import 'package:mobile_books/features/timesheets/data/services/timesheet_service.dart';

class TimesheetSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final timesheetSearchQueryProvider = NotifierProvider<TimesheetSearchQueryNotifier, String>(() {
  return TimesheetSearchQueryNotifier();
});

class TimesheetsNotifier extends AsyncNotifier<List<Timesheet>> {
  @override
  Future<List<Timesheet>> build() {
    return ref.watch(timesheetServiceProvider).getTimesheets();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(timesheetServiceProvider).getTimesheets();
    });
  }

  Future<Timesheet> createTimesheet(Timesheet timesheet) async {
    final service = ref.read(timesheetServiceProvider);
    final result = await service.createTimesheet(timesheet);
    ref.invalidateSelf();
    return result;
  }

  Future<Timesheet> updateTimesheet(int id, Map<String, dynamic> updates) async {
    final service = ref.read(timesheetServiceProvider);
    final result = await service.updateTimesheet(id, updates);
    ref.invalidateSelf();
    ref.invalidate(timesheetDetailsProvider(id));
    return result;
  }

  Future<Timesheet> cancelTimesheet(int id) async {
    final service = ref.read(timesheetServiceProvider);
    final result = await service.cancelTimesheet(id);
    ref.invalidateSelf();
    ref.invalidate(timesheetDetailsProvider(id));
    return result;
  }

  Future<Timesheet> approveTimesheet(int id) async {
    final service = ref.read(timesheetServiceProvider);
    final result = await service.approveTimesheet(id);
    ref.invalidateSelf();
    ref.invalidate(timesheetDetailsProvider(id));
    return result;
  }

  Future<Map<String, dynamic>> convertToInvoice(int id) async {
    final service = ref.read(timesheetServiceProvider);
    final result = await service.convertToInvoice(id);
    ref.invalidateSelf();
    ref.invalidate(timesheetDetailsProvider(id));
    return result;
  }
}

final timesheetsProvider = AsyncNotifierProvider<TimesheetsNotifier, List<Timesheet>>(() {
  return TimesheetsNotifier();
});

final filteredTimesheetsProvider = Provider<AsyncValue<List<Timesheet>>>((ref) {
  final timesheetsState = ref.watch(timesheetsProvider);
  final searchQuery = ref.watch(timesheetSearchQueryProvider).toLowerCase();

  return timesheetsState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((t) {
      final projectName = (t.projectName ?? '').toLowerCase();
      final customerName = (t.customerName ?? '').toLowerCase();
      final staffName = (t.staffName ?? '').toLowerCase();
      final description = (t.description ?? '').toLowerCase();
      final timesheetNumber = (t.timesheetNumber ?? '').toLowerCase();
      
      return projectName.contains(searchQuery) ||
          customerName.contains(searchQuery) ||
          staffName.contains(searchQuery) ||
          description.contains(searchQuery) ||
          timesheetNumber.contains(searchQuery);
    }).toList();
  });
});

final timesheetDetailsProvider = FutureProvider.family<Timesheet, int>((ref, id) {
  return ref.watch(timesheetServiceProvider).getTimesheetById(id);
});
