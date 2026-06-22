import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return DashboardRepository(apiClient);
});

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardModel> getDashboardData({int? month, int? year}) async {
    final queryParameters = <String, dynamic>{};
    if (month != null) queryParameters['month'] = month;
    if (year != null) queryParameters['year'] = year;

    final response = await _apiClient.get(
      '/api/dashboard/monthly-finance-summary',
      queryParameters: queryParameters,
    );

    return DashboardModel.fromJson(response.data);
  }
}
