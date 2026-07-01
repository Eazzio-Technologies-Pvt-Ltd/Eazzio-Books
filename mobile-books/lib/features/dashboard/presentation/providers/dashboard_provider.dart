import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/dashboard/data/models/dashboard_summary.dart';
import 'package:mobile_books/features/dashboard/data/services/dashboard_service.dart';

class DashboardMonthNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().month;

  @override
  set state(int value) => super.state = value;
}

/// Selected month state for dashboard filters (1-12)
final dashboardMonthProvider = NotifierProvider<DashboardMonthNotifier, int>(() {
  return DashboardMonthNotifier();
});

class DashboardYearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;

  @override
  set state(int value) => super.state = value;
}

/// Selected year state for dashboard filters
final dashboardYearProvider = NotifierProvider<DashboardYearNotifier, int>(() {
  return DashboardYearNotifier();
});

/// Async notifier for fetching monthly dashboard metrics summary
class DashboardNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    ref.watch(authNotifierProvider);
    final month = ref.watch(dashboardMonthProvider);
    final year = ref.watch(dashboardYearProvider);
    return ref.watch(dashboardServiceProvider).getMonthlyFinanceSummary(
          month: month,
          year: year,
        );
  }

  /// Forces refreshing of dashboard summary metrics.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final month = ref.read(dashboardMonthProvider);
      final year = ref.read(dashboardYearProvider);
      return ref.read(dashboardServiceProvider).getMonthlyFinanceSummary(
            month: month,
            year: year,
          );
    });
  }
}

final dashboardSummaryProvider = AsyncNotifierProvider<DashboardNotifier, DashboardSummary>(() {
  return DashboardNotifier();
});

/// Fetches projected accounts payments (income)
final projectedPaymentsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  ref.watch(authNotifierProvider);
  final month = ref.watch(dashboardMonthProvider);
  final year = ref.watch(dashboardYearProvider);
  return ref.watch(dashboardServiceProvider).getProjectedPayments(month: month, year: year);
});

/// Fetches projected accounts expenses
final projectedExpensesProvider = FutureProvider<Map<String, dynamic>>((ref) {
  ref.watch(authNotifierProvider);
  final month = ref.watch(dashboardMonthProvider);
  final year = ref.watch(dashboardYearProvider);
  return ref.watch(dashboardServiceProvider).getProjectedExpenses(month: month, year: year);
});
