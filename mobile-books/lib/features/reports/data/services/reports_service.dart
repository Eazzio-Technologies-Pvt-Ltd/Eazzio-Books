import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/reports/data/models/aging_report.dart';
import 'package:mobile_books/features/reports/data/models/balance_sheet.dart';
import 'package:mobile_books/features/reports/data/models/cash_flow.dart';
import 'package:mobile_books/features/reports/data/models/pnl_report.dart';
import 'package:mobile_books/features/reports/data/models/trial_balance.dart';

class ReportsException implements Exception {
  final String message;
  ReportsException(this.message);

  @override
  String toString() => message;
}

class ReportsService {
  final NetworkClient _networkClient;

  ReportsService(this._networkClient);

  /// Fetches Trial Balance report.
  Future<TrialBalanceReport> getTrialBalance({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _networkClient.get(
        '/reports/trial-balance',
        queryParameters: queryParams,
      );
      return TrialBalanceReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch Trial Balance report.';
      throw ReportsException(message);
    } catch (e) {
      throw ReportsException(e.toString());
    }
  }

  /// Fetches Profit and Loss report.
  Future<ProfitAndLossReport> getProfitAndLoss({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _networkClient.get(
        '/reports/pnl',
        queryParameters: queryParams,
      );
      return ProfitAndLossReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch Profit and Loss report.';
      throw ReportsException(message);
    } catch (e) {
      throw ReportsException(e.toString());
    }
  }

  /// Fetches Balance Sheet report.
  Future<BalanceSheetReport> getBalanceSheet({
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _networkClient.get(
        '/reports/balance-sheet',
        queryParameters: queryParams,
      );
      return BalanceSheetReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch Balance Sheet report.';
      throw ReportsException(message);
    } catch (e) {
      throw ReportsException(e.toString());
    }
  }

  /// Fetches Cash Flow report.
  Future<CashFlowReport> getCashFlow({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _networkClient.get(
        '/reports/cash-flow',
        queryParameters: queryParams,
      );
      return CashFlowReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch Cash Flow report.';
      throw ReportsException(message);
    } catch (e) {
      throw ReportsException(e.toString());
    }
  }

  /// Fetches Customer Aging report.
  Future<AgingReport> getCustomerAging({
    String? asOfDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (asOfDate != null) queryParams['as_of_date'] = asOfDate;

      final response = await _networkClient.get(
        '/reports/customer-aging',
        queryParameters: queryParams,
      );
      return AgingReport.fromCustomerJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch Customer Aging report.';
      throw ReportsException(message);
    } catch (e) {
      throw ReportsException(e.toString());
    }
  }

  /// Fetches Vendor Aging report.
  Future<AgingReport> getVendorAging({
    String? asOfDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (asOfDate != null) queryParams['as_of_date'] = asOfDate;

      final response = await _networkClient.get(
        '/reports/vendor-aging',
        queryParameters: queryParams,
      );
      return AgingReport.fromVendorJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch Vendor Aging report.';
      throw ReportsException(message);
    } catch (e) {
      throw ReportsException(e.toString());
    }
  }
}

final reportsServiceProvider = Provider<ReportsService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return ReportsService(networkClient);
});
