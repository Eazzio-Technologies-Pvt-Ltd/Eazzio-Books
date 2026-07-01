import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/dashboard/data/models/dashboard_summary.dart';

class DashboardException implements Exception {
  final String message;
  DashboardException(this.message);

  @override
  String toString() => message;
}

class DashboardService {
  final NetworkClient _networkClient;

  DashboardService(this._networkClient);

  /// Fetches monthly finance summary (KPI cards, select month, next month, bank accounts, and charts).
  Future<DashboardSummary> getMonthlyFinanceSummary({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _networkClient.get(
        '/dashboard/monthly-finance-summary',
        queryParameters: {
          'month': month,
          'year': year,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return DashboardSummary.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch dashboard metrics.';
      throw DashboardException(message);
    } catch (e) {
      throw DashboardException(e.toString());
    }
  }

  /// Fetches projected payments (projected income list and total).
  Future<Map<String, dynamic>> getProjectedPayments({int? month, int? year}) async {
    try {
      final response = await _networkClient.get(
        '/accounts/projected-payments',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch projected payments.';
      throw DashboardException(message);
    } catch (e) {
      throw DashboardException(e.toString());
    }
  }

  /// Fetches projected expenses (projected expenses list and total).
  Future<Map<String, dynamic>> getProjectedExpenses({int? month, int? year}) async {
    try {
      final response = await _networkClient.get(
        '/accounts/projected-expenses',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch projected expenses.';
      throw DashboardException(message);
    } catch (e) {
      throw DashboardException(e.toString());
    }
  }
}

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return DashboardService(networkClient);
});
