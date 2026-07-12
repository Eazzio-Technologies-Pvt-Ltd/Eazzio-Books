import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/dashboard/data/models/notification_model.dart';

class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);

  @override
  String toString() => message;
}

class NotificationService {
  final NetworkClient _networkClient;

  NotificationService(this._networkClient);

  /// Fetches the list of active due installment notifications
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _networkClient.get('/notifications');
      final data = response.data as Map<String, dynamic>;
      final list = data['notifications'] as List? ?? [];
      return list.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to load notifications.';
      throw NotificationException(message);
    } catch (e) {
      throw NotificationException(e.toString());
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return NotificationService(networkClient);
});
