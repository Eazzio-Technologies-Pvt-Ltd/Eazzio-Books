import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/reports/data/models/aging_report.dart';
import 'package:mobile_books/features/reports/data/models/balance_sheet.dart';
import 'package:mobile_books/features/reports/data/models/cash_flow.dart';
import 'package:mobile_books/features/reports/data/models/pnl_report.dart';
import 'package:mobile_books/features/reports/data/models/trial_balance.dart';
import 'package:mobile_books/features/reports/data/services/reports_service.dart';

// --- Trial Balance Providers ---

class TrialBalanceDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  @override
  set state(DateTimeRange? value) => super.state = value;
}

final trialBalanceDateRangeProvider = NotifierProvider<TrialBalanceDateRangeNotifier, DateTimeRange?>(() {
  return TrialBalanceDateRangeNotifier();
});

final trialBalanceReportProvider = FutureProvider<TrialBalanceReport>((ref) {
  ref.watch(authNotifierProvider);
  final dateRange = ref.watch(trialBalanceDateRangeProvider);
  final startStr = dateRange?.start.toIso8601String().split('T')[0];
  final endStr = dateRange?.end.toIso8601String().split('T')[0];
  return ref.watch(reportsServiceProvider).getTrialBalance(
        startDate: startStr,
        endDate: endStr,
      );
});

// --- Profit and Loss Providers ---

class PnlDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  @override
  set state(DateTimeRange? value) => super.state = value;
}

final pnlDateRangeProvider = NotifierProvider<PnlDateRangeNotifier, DateTimeRange?>(() {
  return PnlDateRangeNotifier();
});

final pnlReportProvider = FutureProvider<ProfitAndLossReport>((ref) {
  ref.watch(authNotifierProvider);
  final dateRange = ref.watch(pnlDateRangeProvider);
  final startStr = dateRange?.start.toIso8601String().split('T')[0];
  final endStr = dateRange?.end.toIso8601String().split('T')[0];
  return ref.watch(reportsServiceProvider).getProfitAndLoss(
        startDate: startStr,
        endDate: endStr,
      );
});

// --- Balance Sheet Providers ---

class BalanceSheetEndDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  @override
  set state(DateTime? value) => super.state = value;
}

final balanceSheetEndDateProvider = NotifierProvider<BalanceSheetEndDateNotifier, DateTime?>(() {
  return BalanceSheetEndDateNotifier();
});

final balanceSheetReportProvider = FutureProvider<BalanceSheetReport>((ref) {
  ref.watch(authNotifierProvider);
  final endDate = ref.watch(balanceSheetEndDateProvider);
  final endStr = endDate?.toIso8601String().split('T')[0];
  return ref.watch(reportsServiceProvider).getBalanceSheet(
        endDate: endStr,
      );
});

// --- Cash Flow Providers ---

class CashFlowDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  @override
  set state(DateTimeRange? value) => super.state = value;
}

final cashFlowDateRangeProvider = NotifierProvider<CashFlowDateRangeNotifier, DateTimeRange?>(() {
  return CashFlowDateRangeNotifier();
});

final cashFlowReportProvider = FutureProvider<CashFlowReport>((ref) {
  ref.watch(authNotifierProvider);
  final dateRange = ref.watch(cashFlowDateRangeProvider);
  final startStr = dateRange?.start.toIso8601String().split('T')[0];
  final endStr = dateRange?.end.toIso8601String().split('T')[0];
  return ref.watch(reportsServiceProvider).getCashFlow(
        startDate: startStr,
        endDate: endStr,
      );
});

// --- Customer Aging Providers ---

class CustomerAgingAsOfDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  @override
  set state(DateTime? value) => super.state = value;
}

final customerAgingAsOfDateProvider = NotifierProvider<CustomerAgingAsOfDateNotifier, DateTime?>(() {
  return CustomerAgingAsOfDateNotifier();
});

final customerAgingReportProvider = FutureProvider<AgingReport>((ref) {
  ref.watch(authNotifierProvider);
  final asOfDate = ref.watch(customerAgingAsOfDateProvider);
  final asOfStr = asOfDate?.toIso8601String().split('T')[0];
  return ref.watch(reportsServiceProvider).getCustomerAging(
        asOfDate: asOfStr,
      );
});

// --- Vendor Aging Providers ---

class VendorAgingAsOfDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  @override
  set state(DateTime? value) => super.state = value;
}

final vendorAgingAsOfDateProvider = NotifierProvider<VendorAgingAsOfDateNotifier, DateTime?>(() {
  return VendorAgingAsOfDateNotifier();
});

final vendorAgingReportProvider = FutureProvider<AgingReport>((ref) {
  ref.watch(authNotifierProvider);
  final asOfDate = ref.watch(vendorAgingAsOfDateProvider);
  final asOfStr = asOfDate?.toIso8601String().split('T')[0];
  return ref.watch(reportsServiceProvider).getVendorAging(
        asOfDate: asOfStr,
      );
});
