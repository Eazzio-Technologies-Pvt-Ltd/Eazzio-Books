import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';

class DepositBalances {
  final double pettyCash;
  final double undepositedFunds;

  DepositBalances({required this.pettyCash, required this.undepositedFunds});

  factory DepositBalances.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => v != null ? double.tryParse(v.toString()) ?? 0.0 : 0.0;
    return DepositBalances(
      pettyCash: _d(json['petty_cash']),
      undepositedFunds: _d(json['undeposited_funds']),
    );
  }
}

class DashboardDepositService {
  final NetworkClient _networkClient;

  DashboardDepositService(this._networkClient);

  Future<DepositBalances> getDepositBalances() async {
    try {
      final response = await _networkClient.get('/payments/deposit-balances');
      final data = response.data as Map<String, dynamic>;
      final balances = data['balances'] as Map<String, dynamic>? ?? {};
      return DepositBalances.fromJson(balances);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch deposit balances.';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final dashboardDepositServiceProvider = Provider<DashboardDepositService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return DashboardDepositService(networkClient);
});

final depositBalancesProvider = FutureProvider<DepositBalances>((ref) async {
  return ref.watch(dashboardDepositServiceProvider).getDepositBalances();
});
